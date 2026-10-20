// The note `capsjump check` makes about copies of CapsJump: nothing for one copy or none,
// and with several, a note (never a problem) naming each, which one runs and which one
// gets links.

import Testing
@testable import CapsJumpCore

@Suite struct CopiesTests {
    @Test func oneCopyOrNoneSaysNothing() {
        #expect(Copies.finding(copies: [], linksGoTo: nil, running: []) == nil)
        #expect(Copies.finding(copies: ["/Applications/CapsJump.app"], linksGoTo: "/Applications/CapsJump.app", running: ["/Applications/CapsJump.app"]) == nil)
    }

    @Test func severalCopiesAreANoteNamingWhichRunsAndWhichGetsLinks() {
        let finding = Copies.finding(
            copies: ["/Applications/CapsJump.app", "~/Applications/CapsJump.app", "~/src/CapsJump.app"],
            linksGoTo: "/Applications/CapsJump.app",
            running: ["~/Applications/CapsJump.app"]
        )
        #expect(finding == Finding(.note, "3 copies of CapsJump are on this Mac, and only one of them can hold Accessibility: /Applications/CapsJump.app (links go here), ~/Applications/CapsJump.app (running), ~/src/CapsJump.app"))
    }

    @Test func theCopyThatRunsAndGetsLinksSaysBoth() {
        let finding = Copies.finding(copies: ["/Applications/CapsJump.app", "~/x/CapsJump.app"], linksGoTo: "/Applications/CapsJump.app", running: ["/Applications/CapsJump.app"])
        #expect(finding?.text.hasSuffix("/Applications/CapsJump.app (running; links go here), ~/x/CapsJump.app") == true)
    }
}
