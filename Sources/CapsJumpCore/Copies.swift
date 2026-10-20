// The copies of CapsJump.app on one Mac, as `capsjump check` reports them. macOS keeps one
// Accessibility switch per app ID, and that switch belongs to one particular copy, so with
// several copies the switch can show on while the copy that runs has no access. Several
// copies make a note, never a problem: a developer's Mac always has builds lying around,
// and `check` fails on any problem. One copy says nothing.

import Foundation

public enum Copies {
    /// The note for more than one copy, naming each and which one runs and gets links; nil
    /// for one copy or none. Paths are compared as given.
    public static func finding(copies: [String], linksGoTo: String?, running: [String]) -> Finding? {
        guard copies.count > 1 else { return nil }
        let named = copies.map { path in
            let marks = [running.contains(path) ? "running" : nil, path == linksGoTo ? "links go here" : nil].compactMap { $0 }
            return marks.isEmpty ? path : "\(path) (\(marks.joined(separator: "; ")))"
        }
        return Finding(.note, "\(copies.count) copies of CapsJump are on this Mac, and only one of them can hold Accessibility: \(named.joined(separator: ", "))")
    }

    /// Added to the problem about an unmapped Caps Lock when there is a note on copies.
    public static let accessibilityHint = "; if its switch is already on, it may belong to another copy (see the note on copies)"
}
