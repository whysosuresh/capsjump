// The handover rule with the processes faked: an open waits only when it started a process
// other than the Chrome that ran before, stops at the first look that sees that process
// gone, and gives up after its bound without failing. The pause counts and never sleeps.

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
