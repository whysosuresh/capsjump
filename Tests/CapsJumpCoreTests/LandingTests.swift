// The landing rule with the screen faked: a jump is focused only once a read shows the
// target in front, the acts run once however long it looks, and an error from the acts or
// a read reaches the caller unchanged. The pause counts and never sleeps.

import Testing
@testable import CapsJumpCore

private enum LiveError: Error, Equatable { case accessibilityDenied, readFailed }

private let landed = Foreground(chromeInFront: true, frontApp: "Google Chrome", targetFocused: true)
private let terminal = Foreground(chromeInFront: false, frontApp: "iTerm2", targetFocused: false)
private let otherWindow = Foreground(chromeInFront: true, frontApp: "Google Chrome", targetFocused: false)

/// A screen that shows `frames` in turn, then the last one for every read after.
@MainActor
private final class Screen {
    var frames: [Foreground]
    var acts = 0
    var reads = 0
    var pauses = 0
    var failRead: LiveError?

    init(_ frames: [Foreground]) { self.frames = frames }

    func carryOut() throws(LiveError) { acts += 1 }

    func read() throws(LiveError) -> Foreground {
        reads += 1
        if let failRead { throw failRead }
        return frames.count > 1 ? frames.removeFirst() : frames[0]
    }

    func land(reads: Int = 5) async throws(LiveError) -> NotInFront? {
        try await Landing.land(carryOut: carryOut, read: read, reads: reads) { self.pauses += 1 }
    }
}

@MainActor
@Suite struct LandingTests {
    @Test func theFirstReadLands() async throws {
        let screen = Screen([landed])
        #expect(try await screen.land() == nil)
        #expect((screen.acts, screen.reads, screen.pauses) == (1, 1, 0))
    }

    @Test func aLaterReadLandsWithAPauseBeforeEachReadAfterTheFirst() async throws {
        let screen = Screen([terminal, terminal, landed])
        #expect(try await screen.land() == nil)
        #expect((screen.acts, screen.reads, screen.pauses) == (1, 3, 2))
    }

    @Test func noReadLandsReportsTheAppInFrontAndActsOnce() async throws {
        let screen = Screen([terminal])
        #expect(try await screen.land(reads: 4) == .otherApp("iTerm2"))
        #expect((screen.acts, screen.reads, screen.pauses) == (1, 4, 3))
    }

    @Test func anAppWithoutANameIsStillReported() async throws {
        let screen = Screen([Foreground(chromeInFront: false, frontApp: nil, targetFocused: false)])
        #expect(try await screen.land(reads: 1) == .otherApp(nil))
    }

    @Test func chromeInFrontWithAnotherWindowFocused() async throws {
        let screen = Screen([otherWindow])
        #expect(try await screen.land(reads: 2) == .otherWindow)
    }

    @Test func aRefusedActIsThrownAndNothingIsRead() async {
        let screen = Screen([landed])
        await #expect(throws: LiveError.accessibilityDenied) {
            try await Landing.land(
                carryOut: { () throws(LiveError) in throw .accessibilityDenied },
                read: screen.read,
                reads: 5
            ) { screen.pauses += 1 }
        }
        #expect(screen.reads == 0)
    }

    @Test func aFailedReadIsThrownAndNoFurtherReadIsMade() async {
        let screen = Screen([terminal])
        screen.failRead = .readFailed
        await #expect(throws: LiveError.readFailed) { try await screen.land() }
        #expect((screen.acts, screen.reads, screen.pauses) == (1, 1, 0))
    }
}
