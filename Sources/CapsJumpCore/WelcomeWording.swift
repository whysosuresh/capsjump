// What the Welcome window's "Try it" step says: that a key pressed while the window itself
// is in front was heard (a window move there would have nothing to move), and what the
// first key that ran elsewhere did, in the words the config window uses for the same moves.
// And what its first step adds while Accessibility is missing: the switch in System Settings
// belongs to one copy of CapsJump, so it can show on for another copy than this one. The
// way out is to remove that row and open CapsJump again, so macOS asks for this copy: on
// macOS 26.2 a row added with + was refused, by the running copy and after a relaunch.

import Foundation

public enum WelcomeWording {
    /// A key pressed with Caps Lock while the Welcome window is in front.
    public static func heard(_ trigger: KeyTrigger) -> String {
        let key = KeyNames.name(for: trigger).map { "Caps Lock + \(KeyNames.symbol(for: $0))" } ?? "Caps Lock"
        return "Heard \(key). Now click another window and press it again."
    }

    /// What a key did, once it ran without a failure; `frontApp` is the app whose window a
    /// move moved.
    public static func worked(_ action: KeyAction, frontApp: String?) -> String {
        switch action {
        case let .window(position):
            "\(frontApp.map { "\($0)'s window" } ?? "The window") moved to \(EditorRows.positionSpoken(position))."
        case let .app(target):
            switch target {
            case let .name(name): "\(name) came forward."
            case let .path(path): "\(EditorRows.appName(path)) came forward."
            }
        case let .site(name):
            "\(name) is in front, in its Chrome account."
        case .url:
            "The link opened."
        }
    }

    /// The line under step 1 while Accessibility is missing; `copies` are the paths of every
    /// copy on this Mac, and `this` the running one's.
    public static func alreadyOn(copies: [String], this: String) -> String {
        let fix = "Select CapsJump in the list and remove it with −, then quit CapsJump from the menu bar and open it again, and turn it on when macOS asks."
        let others = copies.filter { $0 != this }
        guard let first = others.first else {
            return "Already switched on? That switch is for an older copy of CapsJump. \(fix)"
        }
        let elsewhere = others.count == 1 ? "The other is at \(first)." : "The others are at \(others.joined(separator: ", "))."
        return "Already switched on? This Mac has \(others.count + 1) copies of CapsJump, and the switch can belong to only one. This one is at \(this). \(elsewhere) \(fix)"
    }
}
