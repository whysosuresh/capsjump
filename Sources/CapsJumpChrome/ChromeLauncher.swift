// Opens a URL in one Chrome profile, the way `open -na "Google Chrome" --args
// --profile-directory=<dir> <url>` does: a new Chrome instance is asked for, which hands
// the URL to the running Chrome (a new tab in that profile's window, or a new window) or
// starts Chrome when none runs. Done through NSWorkspace, so no process is spawned. An open
// returns once that new instance has handed the page over and quit, so the next jump's
// script cannot reach the quitting process.

import AppKit
import CapsJumpCore

@MainActor
public enum ChromeLauncher {
    /// The new instance quit 44-87 ms after the open returned in 24 measured opens; an open
    /// looks for up to 2 s, and the next key waits that long at most.
    private static let handoverReads = 40
    private static let handoverPause = Duration.milliseconds(50)

    public static var runningChrome: NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: Identity.chromeBundleID).first { !$0.isTerminated }
    }

    public static func open(_ url: URL, profileDirectory: String) async throws(ChromeError) {
        let before = runningChrome
        let launched = try await launch(arguments: ["--profile-directory=\(profileDirectory)", url.absoluteString], activates: true, newInstance: true)
        await Handover.wait(launched: launched, before: before, isGone: { launched.isTerminated }, reads: handoverReads) {
            try? await Task.sleep(for: handoverPause)
        }
    }

    /// Starts Chrome without asking it for any page, and waits until it runs.
    public static func start(timeout: Duration = .seconds(20)) async throws(ChromeError) -> NSRunningApplication {
        if let running = runningChrome { return running }
        try await launch(arguments: [], activates: false, newInstance: false)
        let clock = ContinuousClock()
        let deadline = clock.now + timeout
        while clock.now < deadline {
            if let running = runningChrome, running.isFinishedLaunching { return running }
            try? await Task.sleep(for: .milliseconds(200))
        }
        throw .launch("Chrome did not finish starting within \(timeout)")
    }

    @discardableResult
    private static func launch(arguments: [String], activates: Bool, newInstance: Bool) async throws(ChromeError) -> NSRunningApplication {
        guard let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Identity.chromeBundleID) else {
            throw .notInstalled
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.arguments = arguments
        configuration.activates = activates
        configuration.createsNewApplicationInstance = newInstance
        do {
            return try await NSWorkspace.shared.openApplication(at: app, configuration: configuration)
        } catch {
            throw .launch(error.localizedDescription)
        }
    }
}
