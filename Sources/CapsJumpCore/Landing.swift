// Whether a focus landed: after the acts that bring a window forward, look at the screen
// until it shows that window in front, for a bounded number of reads. Waiting re-reads the
// screen and never repeats an act, and an error from the acts or a read (a refused
// permission) is thrown as it came. The live side carries the acts out in the order macOS
// needs; the rule that a jump says it landed only once it has seen so is here.

import Foundation

/// What one look at the screen found.
public struct Foreground: Sendable, Equatable {
    public let chromeInFront: Bool
    /// The front app's name, when it has one.
    public let frontApp: String?
    /// The target is Chrome's focused window.
    public let targetFocused: Bool

    public init(chromeInFront: Bool, frontApp: String?, targetFocused: Bool) {
        self.chromeInFront = chromeInFront
        self.frontApp = frontApp
        self.targetFocused = targetFocused
    }

    /// Why the target isn't in front, or nil when it is.
    public var notInFront: NotInFront? {
        guard chromeInFront else { return .otherApp(frontApp) }
        return targetFocused ? nil : .otherWindow
    }
}

public enum NotInFront: Sendable, Equatable {
    /// Another app stayed in front: its name, when it has one.
    case otherApp(String?)
    /// Chrome came forward with another of its windows focused.
    case otherWindow
}

public enum Landing {
    /// Runs `carryOut` once, then `read` up to `reads` times with `pause` between reads,
    /// until a read shows the target in front. Returns nil when one does, else what the
    /// last read found.
    public static func land<E: Error>(
        isolation: isolated (any Actor)? = #isolation,
        carryOut: () throws(E) -> Void,
        read: () throws(E) -> Foreground,
        reads: Int,
        pause: () async -> Void
    ) async throws(E) -> NotInFront? {
        precondition(reads > 0, "a landing is only known by looking")
        try carryOut()
        var missed: NotInFront?
        for attempt in 0..<reads {
            if attempt > 0 { await pause() }
            missed = try read().notInFront
            if missed == nil { return nil }
        }
        return missed
    }
}
