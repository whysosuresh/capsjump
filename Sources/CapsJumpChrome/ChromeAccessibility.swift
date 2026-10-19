// Chrome's windows through Accessibility: the whole window titles, which end in the
// profile's label, raising one exact window, and which window has the focus. Read straight
// from Chrome's process, so no second Automation grant (for System Events) is needed.

import AppKit
import ApplicationServices

public struct AXWindow {
    public let title: String
    public let element: AXUIElement
}

@MainActor
public enum ChromeAccessibility {
    public static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Chrome's standard windows (minimized ones included), front to back.
    public static func windows(of app: NSRunningApplication) throws(ChromeError) -> [AXWindow] {
        guard isTrusted else { throw .accessibilityDenied }
        let element = AXUIElementCreateApplication(app.processIdentifier)
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, kAXWindowsAttribute as CFString, &value)
        switch status {
        case .success: break
        case .noValue: return []
        default: throw failure(status, during: .read)
        }
        let windows = value as? [AXUIElement] ?? []
        return windows.compactMap { window in
            guard string(window, kAXSubroleAttribute) == kAXStandardWindowSubrole as String else { return nil }
            return AXWindow(title: string(window, kAXTitleAttribute) ?? "", element: window)
        }
    }

    /// Makes the window Chrome's main window and raises it above Chrome's others.
    /// Un-minimizing is the script's (`ChromeScripting.focus`).
    public static func raise(_ window: AXUIElement) throws(ChromeError) {
        let main = AXUIElementSetAttributeValue(window, kAXMainAttribute as CFString, kCFBooleanTrue)
        guard main == .success else { throw failure(main, during: .raise) }
        let raised = AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        guard raised == .success else { throw failure(raised, during: .raise) }
    }

    /// Chrome's focused window, or nil when it has none.
    public static func focusedWindow(of app: NSRunningApplication) throws(ChromeError) -> AXUIElement? {
        let element = AXUIElementCreateApplication(app.processIdentifier)
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, kAXFocusedWindowAttribute as CFString, &value)
        switch status {
        case .success: break
        case .noValue: return nil
        default: throw failure(status, during: .read)
        }
        guard let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }

    enum Step { case read, raise }

    /// What a failed status means for the step that got it.
    static func failure(_ status: AXError, during step: Step) -> ChromeError {
        switch status {
        case .apiDisabled: .accessibilityDenied
        case .invalidUIElement: .windowGone
        default: step == .read ? .accessibility(code: status.rawValue) : .raise(code: status.rawValue)
        }
    }

    private static func string(_ element: AXUIElement, _ attribute: String) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value as? String
    }
}
