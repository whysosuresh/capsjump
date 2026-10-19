// When an open has handed its page over: opening in one Chrome profile starts a second
// Chrome process, which hands the page to the running Chrome and quits. Until it quits,
// two processes carry Chrome's bundle id and a script can reach the quitting one; and
// Chrome can show the page's tab a moment after that. So an open is over once the process
// is gone and a jump to the site would focus its tab, and the next key, landing after it,
// finds that tab instead of failing or opening a second one. Each wait is bounded and never
// fails the open; when no Chrome ran before, the opened process is Chrome itself and
// stays, so it is not watched. Generic over the process so this stays free of AppKit; the
// live side compares NSRunningApplications with `isEqual:`, as Apple asks, never by pid.

import Foundation

public enum Handover {
    /// Looks at `isGone` up to `reads` times with `pause` between looks, when `launched` is
    /// not the Chrome that ran `before` the open. Returns whether the opened process is gone
    /// or never needed watching; false when it was still there at the last look.
    @discardableResult
    public static func wait<Process: Equatable>(
        isolation: isolated (any Actor)? = #isolation,
        launched: Process,
        before: Process?,
        isGone: () -> Bool,
        reads: Int,
        pause: () async -> Void
    ) async -> Bool {
        precondition(reads > 0, "a handover is only known by looking")
        guard let before, before != launched else { return true }
        return await look(reads: reads, pause: pause, until: isGone)
    }

    /// After `target`'s page was opened, asks `decide` what a jump to it would do, up to
    /// `reads` times with `pause` between, until it would focus a tab. Returns whether one
    /// would. A target whose label another profile shares is always opened, so it is not
    /// looked for; a look that could not read Chrome (nil) ends the wait, and the next jump
    /// meets and reports what it found.
    @discardableResult
    public static func waitForTab(
        isolation: isolated (any Actor)? = #isolation,
        target: Target,
        reads: Int,
        decide: () -> Action?,
        pause: () async -> Void
    ) async -> Bool {
        precondition(reads > 0, "a handover is only known by looking")
        guard target.canFocus else { return false }
        var unreadable = false
        let shown = await look(reads: reads, pause: pause) {
            guard let action = decide() else {
                unreadable = true
                return true
            }
            if case .focus = action { return true }
            return false
        }
        return shown && !unreadable
    }

    private static func look(
        isolation: isolated (any Actor)? = #isolation,
        reads: Int,
        pause: () async -> Void,
        until done: () -> Bool
    ) async -> Bool {
        for attempt in 0..<reads {
            if attempt > 0 { await pause() }
            if done() { return true }
        }
        return false
    }
}
