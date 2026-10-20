// What the event tap does with each key event, decided here so every rule is tested.
// Caps Lock arrives as F18 and is always swallowed. While it is held, every key press is
// swallowed and a bound key's action runs once, however long the key is held; a key-up is
// swallowed when its key-down was, even after Caps Lock is let go, and so are that key's
// repeats while it stays down, so no app sees half a key. Everything else passes
// untouched. Whether Caps Lock is held comes with each event, asked of the system, never
// remembered here, so a missed key-up can't leave keys swallowed. While one of CapsJump's
// own windows listens, a key pressed with Caps Lock is swallowed the same way but heard
// instead of run, with what it is bound to, so the listener gets the key and nothing
// jumps. A key field hears every key; the Welcome window hears only a key that would move
// a window or does nothing, and every other key runs. One listener at a time: the last to
// ask, and only it can stop.

import Foundation

public struct KeyEvent: Sendable, Equatable {
    public enum Phase: Sendable {
        case down
        case up
    }

    public let trigger: KeyTrigger
    public let phase: Phase
    /// An auto-repeated key-down.
    public let isRepeat: Bool
    /// Whether the system reports Caps Lock (as F18) down as this event arrives.
    public let capsHeld: Bool

    public init(_ trigger: KeyTrigger, _ phase: Phase, isRepeat: Bool = false, capsHeld: Bool) {
        self.trigger = trigger
        self.phase = phase
        self.isRepeat = isRepeat
        self.capsHeld = capsHeld
    }
}

public enum KeyDecision: Sendable, Equatable {
    case pass
    case swallow
    case run(KeyAction)
    /// Swallowed and handed to the listener with what the key is bound to, if anything;
    /// nothing runs.
    case heard(KeyTrigger, KeyAction?)
}

public struct KeyRules: Sendable {
    /// Which keys a listener hears; the rest run as they would with nobody listening.
    public enum Hearing: Sendable, Equatable {
        /// Every key, bound or not: a key field recording a key.
        case every
        /// A window key and a key with nothing bound. A listener's own window must not be
        /// moved by the key it is listening for; an app, site or link key leaves it alone.
        case windowAndUnbound

        public func hears(_ action: KeyAction?) -> Bool {
            switch self {
            case .every: return true
            case .windowAndUnbound:
                guard let action else { return true }
                switch action {
                case .window: return true
                case .app, .site, .url: return false
                }
            }
        }
    }

    /// Who listens, and what it hears.
    public struct Listener: Sendable, Equatable {
        public let owner: ObjectIdentifier
        public let hearing: Hearing
    }

    /// What each trigger runs; replaced whole when the config changes.
    public var bindings: [KeyTrigger: KeyAction]
    /// Keys whose key-down was swallowed and whose key-up hasn't come yet.
    public private(set) var swallowed: Set<KeyTrigger> = []
    /// The window or key field listening, if any.
    public private(set) var listener: Listener?

    public var isListening: Bool { listener != nil }

    public init(bindings: [KeyTrigger: KeyAction] = [:]) {
        self.bindings = bindings
    }

    /// Each bound key's triggers, all running its action.
    public static func bindings(for config: Config) -> [KeyTrigger: KeyAction] {
        var table: [KeyTrigger: KeyAction] = [:]
        for binding in config.keys {
            for trigger in KeyNames.triggers(for: binding.key) ?? [] {
                table[trigger] = binding.action
            }
        }
        return table
    }

    /// Hands each key pressed with Caps Lock that `hearing` hears to `owner` until it stops;
    /// a listener before is replaced.
    public mutating func listen(_ owner: ObjectIdentifier, hearing: Hearing) {
        listener = Listener(owner: owner, hearing: hearing)
    }

    /// Ends `owner`'s listening; a listener that was replaced changes nothing. With no
    /// owner, ends whoever listens.
    public mutating func stopListening(_ owner: ObjectIdentifier? = nil) {
        if owner == nil || owner == listener?.owner { listener = nil }
    }

    public mutating func decide(_ event: KeyEvent) -> KeyDecision {
        // No keys bound means Caps Lock isn't taken: a real F18 and everything else pass.
        if bindings.isEmpty && swallowed.isEmpty { return .pass }
        if event.trigger == .key(CapsLock.keyCode) { return .swallow }

        switch event.phase {
        case .up:
            return swallowed.remove(event.trigger) == nil ? .pass : .swallow
        case .down:
            // A key still held from a swallowed press keeps being swallowed as it repeats. A
            // fresh press of it means its key-up was missed, and starts over.
            if swallowed.contains(event.trigger) {
                if event.isRepeat { return .swallow }
                swallowed.remove(event.trigger)
            }
            guard event.capsHeld else { return .pass }
            swallowed.insert(event.trigger)
            guard !event.isRepeat else { return .swallow }
            let action = bindings[event.trigger]
            if let listener, listener.hearing.hears(action) { return .heard(event.trigger, action) }
            guard let action else { return .swallow }
            return .run(action)
        }
    }
}
