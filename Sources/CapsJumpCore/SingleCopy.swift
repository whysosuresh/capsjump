// Which CapsJump runs when another copy already does. macOS keeps one Accessibility switch
// per app ID, and that switch belongs to one particular copy of the app, so two copies
// running side by side means one of them is refused the keys while the switch shows on.
// The rule: a copy started by a link or at login leaves the keys to the copy that was
// running and hands its links over; a copy the person opened (Finder, Spotlight, the Dock)
// asks the running one to quit and takes over, so they get the copy they asked for. Only
// copies launched before this one count, so two copies started together settle on the
// earlier one. A copy with no launch date counts as launched before any that has one, and
// two without one both start, as they would without this rule; a copy with no bundle
// can't be handed a link, so it doesn't count. Generic over the process so this stays free
// of AppKit; the live side compares NSRunningApplications with `isEqual:`, never by pid.

import Foundation

public enum SingleCopy {
    /// Another process carrying CapsJump's app ID, as the launching copy sees it.
    public struct Copy<Process> {
        public let process: Process
        public let launched: Date?
        /// Whether it has a bundle a link can be sent to.
        public let hasBundle: Bool
        public let terminated: Bool

        public init(process: Process, launched: Date?, hasBundle: Bool, terminated: Bool) {
            self.process = process
            self.launched = launched
            self.hasBundle = hasBundle
            self.terminated = terminated
        }
    }

    public enum Decision<Process> {
        /// No earlier copy runs: this one starts the keys.
        case lead
        /// This copy sends its links to `to` and quits without starting anything.
        case handOver(to: Process)
        /// This copy asks `from` to quit, then starts the keys.
        case takeOver(from: [Process])
    }

    /// What `this`, launched at `launched`, does beside the `running` copies. A copy the
    /// person opened takes over from every earlier one; any other hands over to the
    /// earliest.
    public static func decide<Process: Equatable>(
        this: Process,
        launched: Date?,
        running: [Copy<Process>],
        openedByPerson: Bool
    ) -> Decision<Process> {
        let mine = launched ?? .distantPast
        let earlier = running
            .filter { $0.process != this && !$0.terminated && $0.hasBundle && ($0.launched ?? .distantPast) < mine }
            .sorted { ($0.launched ?? .distantPast) < ($1.launched ?? .distantPast) }
        guard let first = earlier.first else { return .lead }
        return openedByPerson ? .takeOver(from: earlier.map(\.process)) : .handOver(to: first.process)
    }
}

extension SingleCopy.Decision: Equatable where Process: Equatable {}
