// The handover rules with the processes and jumps faked: an open waits only when it started
// a process other than the Chrome that ran before, stops at the first look that sees that
// process gone, then waits for the page's tab until a jump would focus it; each wait gives
// up after its bound without failing. The pause counts and never sleeps.

import Foundation
import Testing
@testable import CapsJumpCore

/// A process that quits after `looksUntilGone` looks, or never when nil.
@MainActor
private final class Helper {
    let looksUntilGone: Int?
    var looks = 0
    var pauses = 0

    init(goneAfter looksUntilGone: Int?) { self.looksUntilGone = looksUntilGone }

    func isGone() -> Bool {
        looks += 1
        guard let looksUntilGone else { return false }
        return looks >= looksUntilGone
    }

    func wait(launched: Int, before: Int?, reads: Int = 5) async -> Bool {
        await Handover.wait(launched: launched, before: before, isGone: isGone, reads: reads) { self.pauses += 1 }
    }
}

@MainActor
@Suite struct HandoverTests {
    @Test func noChromeRanBeforeSoTheOpenedProcessIsChromeAndNothingIsWatched() async {
        let helper = Helper(goneAfter: nil)
        #expect(await helper.wait(launched: 2, before: nil))
        #expect((helper.looks, helper.pauses) == (0, 0))
    }

    @Test func theOpenReturnedTheChromeThatRanAndNothingIsWatched() async {
        let helper = Helper(goneAfter: nil)
        #expect(await helper.wait(launched: 1, before: 1))
        #expect((helper.looks, helper.pauses) == (0, 0))
    }

    @Test func aHelperAlreadyGoneTakesOneLookAndNoPause() async {
        let helper = Helper(goneAfter: 1)
        #expect(await helper.wait(launched: 2, before: 1))
        #expect((helper.looks, helper.pauses) == (1, 0))
    }

    @Test func theWaitStopsAtTheLookThatSeesTheHelperGone() async {
        let helper = Helper(goneAfter: 3)
        #expect(await helper.wait(launched: 2, before: 1))
        #expect((helper.looks, helper.pauses) == (3, 2))
    }

    @Test func aHelperThatStaysIsGivenUpOnAfterTheBound() async {
        let helper = Helper(goneAfter: nil)
        #expect(await helper.wait(launched: 2, before: 1, reads: 4) == false)
        #expect((helper.looks, helper.pauses) == (4, 3))
    }
}

/// The jump decisions the looks see, in turn, then the last one for every look after; nil
/// is a look that could not read Chrome.
@MainActor
private final class Tabs {
    var decisions: [Action?]
    var looks = 0
    var pauses = 0

    init(_ decisions: [Action?]) { self.decisions = decisions }

    func decide() -> Action? {
        looks += 1
        return decisions.count > 1 ? decisions.removeFirst() : decisions[0]
    }

    func wait(shared: Bool = false, reads: Int = 5) async -> Bool {
        await Handover.waitForTab(target: target(shared: shared), reads: reads, decide: decide) { self.pauses += 1 }
    }
}

private let profile = ChromeProfile(directory: "Profile 31", name: "Demo Personal", email: "", givenName: "")

private func target(shared: Bool) -> Target {
    Target(
        site: Site(name: "demo", account: nil, profile: "Profile 31", open: URL(string: "https://example.com/demo")!, match: ["example.com/demo"]),
        profile: profile,
        sharedLabelWith: shared ? [ChromeProfile(directory: "Profile 32", name: "Demo Personal", email: "", givenName: "")] : [],
            onlyProfile: false
    )
}

private let opens = Action.open(profileDirectory: "Profile 31", url: URL(string: "https://example.com/demo")!, reason: .noMatchingTab)
private let focuses = Action.focus(windowID: "7", tabIndex: 2, titleIndex: 0)

@MainActor
@Suite struct TabHandoverTests {
    @Test func aTargetThatIsAlwaysOpenedIsNotLookedFor() async {
        let tabs = Tabs([focuses])
        #expect(await tabs.wait(shared: true) == false)
        #expect((tabs.looks, tabs.pauses) == (0, 0))
    }

    @Test func aTabAlreadyShownTakesOneLookAndNoPause() async {
        let tabs = Tabs([focuses])
        #expect(await tabs.wait())
        #expect((tabs.looks, tabs.pauses) == (1, 0))
    }

    @Test func theWaitStopsAtTheLookThatWouldFocus() async {
        let tabs = Tabs([opens, opens, focuses])
        #expect(await tabs.wait())
        #expect((tabs.looks, tabs.pauses) == (3, 2))
    }

    @Test func aLookThatCannotReadChromeEndsTheWait() async {
        let tabs = Tabs([opens, nil, focuses])
        #expect(await tabs.wait() == false)
        #expect((tabs.looks, tabs.pauses) == (2, 1))
    }

    @Test func aTabThatNeverShowsIsGivenUpOnAfterTheBound() async {
        let tabs = Tabs([opens])
        #expect(await tabs.wait(reads: 4) == false)
        #expect((tabs.looks, tabs.pauses) == (4, 3))
    }
}
