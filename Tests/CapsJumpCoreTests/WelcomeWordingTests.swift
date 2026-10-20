// What the Welcome window's "Try it" step says for a key heard in the window and for each
// kind of key that ran, and what step 1 adds about a switch that is already on, with one
// copy of CapsJump and with several.

import Foundation
import Testing
@testable import CapsJumpCore

@Suite struct WelcomeWordingTests {
    @Test func aHeardKeyIsNamedAsItIsPressed() {
        #expect(WelcomeWording.heard(.key(0x7B)) == "Heard Caps Lock + ←. Now click another window and press it again.")
        #expect(WelcomeWording.heard(.key(0x05)) == "Heard Caps Lock + G. Now click another window and press it again.")
        #expect(WelcomeWording.heard(.key(0x31)) == "Heard Caps Lock. Now click another window and press it again.")
    }

    @Test func eachKindOfKeySaysWhatItDid() {
        #expect(WelcomeWording.worked(.window(.leftHalf), frontApp: "Safari") == "Safari's window moved to the left half.")
        #expect(WelcomeWording.worked(.window(.maximize), frontApp: nil) == "The window moved to the whole screen.")
        #expect(WelcomeWording.worked(.app(.name("Terminal")), frontApp: nil) == "Terminal came forward.")
        #expect(WelcomeWording.worked(.app(.path("~/Applications/Obsidian.app")), frontApp: nil) == "Obsidian came forward.")
        #expect(WelcomeWording.worked(.site("github"), frontApp: nil) == "github is in front, in its Chrome account.")
        #expect(WelcomeWording.worked(.url(URL(string: "slack://open")!), frontApp: nil) == "The link opened.")
    }

    @Test func withOneCopyTheSwitchThatIsOnIsAnOlderBuildOfIt() {
        let one = "Already switched on? That switch is for an older copy of CapsJump. Select CapsJump in the list and remove it with −, then quit CapsJump from the menu bar and open it again, and turn it on when macOS asks."
        #expect(WelcomeWording.alreadyOn(copies: ["/Applications/CapsJump.app"], this: "/Applications/CapsJump.app") == one)
        #expect(WelcomeWording.alreadyOn(copies: [], this: "/Applications/CapsJump.app") == one)
    }

    @Test func withSeveralCopiesEachIsNamedAndThisOneApart() {
        #expect(WelcomeWording.alreadyOn(copies: ["/Applications/CapsJump.app", "~/Applications/CapsJump.app"], this: "/Applications/CapsJump.app")
            == "Already switched on? This Mac has 2 copies of CapsJump, and the switch can belong to only one. This one is at /Applications/CapsJump.app. The other is at ~/Applications/CapsJump.app. Select CapsJump in the list and remove it with −, then quit CapsJump from the menu bar and open it again, and turn it on when macOS asks.")
        #expect(WelcomeWording.alreadyOn(copies: ["/Applications/CapsJump.app", "~/a/CapsJump.app", "~/b/CapsJump.app"], this: "~/a/CapsJump.app")
            == "Already switched on? This Mac has 3 copies of CapsJump, and the switch can belong to only one. This one is at ~/a/CapsJump.app. The others are at /Applications/CapsJump.app, ~/b/CapsJump.app. Select CapsJump in the list and remove it with −, then quit CapsJump from the menu bar and open it again, and turn it on when macOS asks.")
    }

    @Test func aCopyMissingFromTheListStillCountsItself() {
        #expect(WelcomeWording.alreadyOn(copies: ["/Applications/CapsJump.app"], this: "/tmp/CapsJump.app").hasPrefix("Already switched on? This Mac has 2 copies"))
    }
}
