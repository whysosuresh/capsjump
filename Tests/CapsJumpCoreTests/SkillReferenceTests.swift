// The coding-agent skill (skills/capsjump/SKILL.md) carries a short reference of the
// config's names, read by agents that never see this code. Its names that come from
// enumerations are checked here, so a new window move or action can't ship without the
// skill knowing it. The file is read from the checkout this test was built from.

import Foundation
import Testing
@testable import CapsJumpCore

@Suite struct SkillReferenceTests {
    private static let folder = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("skills/capsjump")

    private let text = (try? String(contentsOf: folder.appendingPathComponent("SKILL.md"), encoding: .utf8)) ?? ""

    @Test func namesItselfAfterItsFolder() {
        let frontmatter = text.components(separatedBy: "---\n").dropFirst().first ?? ""
        let name = frontmatter.split(separator: "\n").first { $0.hasPrefix("name: ") }?.dropFirst("name: ".count)
        #expect(name.map(String.init) == Self.folder.lastPathComponent)
    }

    @Test func knowsEveryWindowMove() {
        for position in WindowPosition.allCases {
            #expect(text.contains("`\(position.rawValue)`"), "the skill's reference lacks the window move `\(position.rawValue)`")
        }
    }

    @Test func knowsEveryAction() {
        for kind in ActionSource.Kind.allCases {
            #expect(text.contains("`\(kind.rawValue)`"), "the skill's reference lacks the action `\(kind.rawValue)`")
        }
    }
}
