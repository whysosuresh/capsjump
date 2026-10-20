// The one-copy rule with the processes faked as numbers: a copy alone leads; beside an
// earlier copy, one started by a link or at login hands over to it and one the person
// opened takes over; later, quitting or bundle-less copies don't count, and two copies
// started together settle on the earlier one.

import Foundation
import Testing
@testable import CapsJumpCore

private let t0 = Date(timeIntervalSince1970: 1_000)

private func copy(_ process: Int, at seconds: Double?, hasBundle: Bool = true, terminated: Bool = false) -> SingleCopy.Copy<Int> {
    SingleCopy.Copy(process: process, launched: seconds.map { t0.addingTimeInterval($0) }, hasBundle: hasBundle, terminated: terminated)
}

private func decide(launchedAt seconds: Double? = 10, running: [SingleCopy.Copy<Int>], openedByPerson: Bool = false) -> SingleCopy.Decision<Int> {
    SingleCopy.decide(this: 1, launched: seconds.map { t0.addingTimeInterval($0) }, running: running, openedByPerson: openedByPerson)
}

@Suite struct SingleCopyTests {
    @Test func aCopyAloneLeads() {
        #expect(decide(running: []) == .lead)
        #expect(decide(running: [copy(1, at: 10)]) == .lead)
    }

    @Test func aLinkOrLoginLaunchHandsOverToTheRunningCopy() {
        #expect(decide(running: [copy(1, at: 10), copy(2, at: 0)]) == .handOver(to: 2))
    }

    @Test func aCopyThePersonOpenedTakesOver() {
        #expect(decide(running: [copy(2, at: 0)], openedByPerson: true) == .takeOver(from: [2]))
    }

    @Test func aTakeOverQuitsEveryEarlierCopyAndAHandOverGoesToTheEarliest() {
        let running = [copy(3, at: 5), copy(2, at: 0), copy(4, at: 20)]
        #expect(decide(running: running, openedByPerson: true) == .takeOver(from: [2, 3]))
        #expect(decide(running: running) == .handOver(to: 2))
    }

    @Test func aCopyLaunchedLaterDefersToThisOneSoTwoStartedTogetherSettle() {
        #expect(decide(running: [copy(2, at: 11)]) == .lead)
        #expect(decide(running: [copy(2, at: 11)], openedByPerson: true) == .lead)
        // The same pair, seen from the later copy.
        #expect(SingleCopy.decide(this: 2, launched: t0.addingTimeInterval(11), running: [copy(1, at: 10)], openedByPerson: false) == .handOver(to: 1))
    }

    @Test func aQuittingCopyOrOneWithNoBundleDoesNotCount() {
        #expect(decide(running: [copy(2, at: 0, terminated: true)]) == .lead)
        #expect(decide(running: [copy(2, at: 0, hasBundle: false)]) == .lead)
    }

    @Test func aMissingLaunchDateCountsAsEarlierThanAnyKnownOne() {
        #expect(decide(running: [copy(2, at: nil)]) == .handOver(to: 2))
        #expect(decide(launchedAt: nil, running: [copy(2, at: 0)]) == .lead)
        #expect(decide(running: [copy(3, at: 0), copy(2, at: nil)]) == .handOver(to: 2))
    }

    @Test func twoCopiesWithNoLaunchDateBothStartAsWithoutTheRule() {
        #expect(decide(launchedAt: nil, running: [copy(2, at: nil)]) == .lead)
    }
}
