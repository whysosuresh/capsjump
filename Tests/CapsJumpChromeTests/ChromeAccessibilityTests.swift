// How Accessibility's statuses become the errors people read: a refused permission is a
// refused permission whichever step met it, a window that went away is said so, and any
// other status names the step that failed. No Chrome needed.

import ApplicationServices
import Testing
@testable import CapsJumpChrome

@MainActor
@Suite struct ChromeAccessibilityTests {
    @Test func aRefusedPermissionIsTheSameForEveryStep() {
        #expect(ChromeAccessibility.failure(.apiDisabled, during: .read) == .accessibilityDenied)
        #expect(ChromeAccessibility.failure(.apiDisabled, during: .raise) == .accessibilityDenied)
    }

    @Test func aWindowThatWentAwayIsWindowGone() {
        #expect(ChromeAccessibility.failure(.invalidUIElement, during: .read) == .windowGone)
        #expect(ChromeAccessibility.failure(.invalidUIElement, during: .raise) == .windowGone)
    }

    @Test func anyOtherStatusNamesTheStep() {
        #expect(ChromeAccessibility.failure(.cannotComplete, during: .read) == .accessibility(code: AXError.cannotComplete.rawValue))
        #expect(ChromeAccessibility.failure(.cannotComplete, during: .raise) == .raise(code: AXError.cannotComplete.rawValue))
        #expect(ChromeError.raise(code: -25204).description == "Accessibility could not bring Chrome's window forward (error -25204)")
    }

    @Test func notInFrontNamesTheAppNeverAPage() {
        #expect(ChromeError.notInFront(.otherApp("iTerm2")).description == "the window didn't come to the front; iTerm2 stayed in front")
        #expect(ChromeError.notInFront(.otherApp(nil)).description == "the window didn't come to the front; another app stayed in front")
        #expect(ChromeError.notInFront(.otherWindow).description == "Chrome kept another of its windows in front")
    }
}
