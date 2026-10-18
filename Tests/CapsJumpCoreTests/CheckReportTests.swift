// What `capsjump check --json` reports: the file read, whether anything is wrong, and the
// findings about the file apart from those about the app, so a script fixes the first and
// hands the second to the person. And the note on a file outside the layout CapsJump
// writes, which `Checkup.run` leaves to its own function.

import Foundation
import Testing
@testable import CapsJumpCore

@Suite struct CheckReportTests {
    private let config = Config(
        sites: [Site(name: "github", account: "alex@acme.dev", profile: nil, open: URL(string: "https://github.com/")!, match: ["github.com/"])],
        keys: [KeyBinding(key: "g", action: .site("github")), KeyBinding(key: "f", action: .window(.maximize))]
    )

    @Test func okUnlessAProblemOnEitherSide() {
        let fine = Finding(.ok, "fine")
        let note = Finding(.note, "a note")
        let problem = Finding(.problem, "broken")
        #expect(CheckReport(config: "/c.yaml", file: [fine, note], app: [fine]).ok)
        #expect(!CheckReport(config: "/c.yaml", file: [problem], app: [fine]).ok)
        #expect(!CheckReport(config: "/c.yaml", file: [fine], app: [problem]).ok)
    }

    @Test func printsTheFileAndTheAppApart() throws {
        let report = CheckReport(
            config: "/Users/kim/dotfiles/capsjump.yaml",
            file: [Finding(.ok, "`f` → window maximize")],
            app: [Finding(.problem, "CapsJump.app is not running")]
        )
        #expect(try JSONOutput.render(report) == """
        {
          "app" : [
            {
              "level" : "problem",
              "text" : "CapsJump.app is not running"
            }
          ],
          "config" : "/Users/kim/dotfiles/capsjump.yaml",
          "file" : [
            {
              "level" : "ok",
              "text" : "`f` → window maximize"
            }
          ],
          "ok" : false
        }
        """)
    }

    private func layout(_ text: String?) -> Finding? {
        Checkup.layout(configText: text, configPath: "~/.capsjump.yaml")
    }

    @Test func aFileOutsideTheLayoutGetsANote() {
        let written = ConfigWriter.render(config)
        let expected = Finding(.note, "~/.capsjump.yaml isn't in the layout CapsJump writes; `capsjump tidy` rewrites it, and Edit Config… asks before saving over it")
        #expect(layout("# my keys\n" + written) == expected)
        #expect(layout("keys:\n  f: { window: maximize }\n") == expected)
    }

    @Test func aFileInTheLayoutGetsNone() {
        let written = ConfigWriter.render(config)
        #expect(layout(written) == nil)
        #expect(layout(String(ConfigWriter.body(of: written))) == nil)
    }

    @Test func aMissingOrBrokenFileGetsNone() {
        #expect(layout(nil) == nil)
        #expect(layout("keys:\n  G: { window: maximize }\n") == nil)
    }
}
