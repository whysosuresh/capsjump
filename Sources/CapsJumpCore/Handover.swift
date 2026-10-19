// When an open has handed its page over: opening in one Chrome profile starts a second
// Chrome process, which hands the page to the running Chrome and quits. Until it quits,
// two processes carry Chrome's bundle id and a script can reach the quitting one, so the
// open is over only once it is gone. The wait is bounded and never fails the open; when no
// Chrome ran before, the opened process is Chrome itself and stays, so nothing is watched.
// Generic over the process so this stays free of AppKit; the live side compares
// NSRunningApplications with `isEqual:`, as Apple asks, never by pid.

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
        for attempt in 0..<reads {
            if attempt > 0 { await pause() }
            if isGone() { return true }
        }
        return false
    }
}
