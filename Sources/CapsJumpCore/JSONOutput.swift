// How the CLI prints JSON: indented, keys sorted so the output is the same every run, and
// slashes left as they are, so paths and links read as written.

import Foundation

public enum JSONOutput {
    public static func render(_ value: some Encodable) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return String(decoding: try encoder.encode(value), as: UTF8.self)
    }
}
