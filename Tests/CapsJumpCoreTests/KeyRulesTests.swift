// Every rule of the event tap: Caps Lock is swallowed, a bound key runs once, an unbound
// key does nothing while Caps Lock is held, a swallowed press swallows its key-up and
// repeats, and nothing is touched when no key is bound. While a key field listens, a key
// pressed with Caps Lock is heard instead of run, with what it is bound to, swallowed all
// the same, and only the field listening can stop it; while the Welcome window listens,
// only a window key or an unbound one is heard, and every other key runs. Caps Lock pressed
// with Shift held switches its lock as it is let go, and Caps Lock alone, Shift after Caps
// Lock and a press used with a key don't. Then where each window move puts the window.

import Foundation
import Testing
@testable import CapsJumpCore

@Suite struct KeyRulesTests {
    private let caps = KeyTrigger.key(CapsLock.keyCode)
    private let g = KeyTrigger.key(5)
    private let x = KeyTrigger.key(7)
    private let volumeUp = KeyTrigger.media(0)
    private let site = KeyAction.site("github")
    private let window = KeyAction.window(.maximize)

    private func rules() throws -> KeyRules {
        let config = try ConfigParser.parse("""
        sites:
          - name: github
            account: alex@acme.dev
            open: https://github.com/
        keys:
          g: { site: github }
          f12: { window: maximize }
        """)
        return KeyRules(bindings: KeyRules.bindings(for: config))
    }

    @Test func bindingsCoverEveryTriggerOfAName() throws {
        let bindings = try rules().bindings
        #expect(bindings == [g: site, .key(111): window, volumeUp: window])
    }

    @Test func capsLockItselfIsAlwaysSwallowed() throws {
        var rules = try rules()
        #expect(rules.decide(KeyEvent(caps, .down, capsHeld: true, shiftHeld: false)) == .swallow)
        #expect(rules.decide(KeyEvent(caps, .down, isRepeat: true, capsHeld: true, shiftHeld: false)) == .swallow)
        #expect(rules.decide(KeyEvent(caps, .up, capsHeld: false, shiftHeld: false)) == .swallow)
    }

    @Test func aBoundKeyRunsOnceAndIsSwallowed() throws {
        var rules = try rules()
        #expect(rules.decide(KeyEvent(g, .down, capsHeld: true, shiftHeld: false)) == .run(site))
        #expect(rules.decide(KeyEvent(g, .down, isRepeat: true, capsHeld: true, shiftHeld: false)) == .swallow)
        #expect(rules.decide(KeyEvent(g, .down, isRepeat: true, capsHeld: true, shiftHeld: false)) == .swallow)
        #expect(rules.decide(KeyEvent(g, .up, capsHeld: true, shiftHeld: false)) == .swallow)
        #expect(rules.swallowed.isEmpty)
    }

    @Test func theTopRowRunsItsBinding() throws {
        var rules = try rules()
        #expect(rules.decide(KeyEvent(volumeUp, .down, capsHeld: true, shiftHeld: false)) == .run(window))
        #expect(rules.decide(KeyEvent(volumeUp, .up, capsHeld: true, shiftHeld: false)) == .swallow)
        #expect(rules.decide(KeyEvent(.key(111), .down, capsHeld: true, shiftHeld: false)) == .run(window))
    }

    @Test func anUnboundKeyDoesNothingWhileCapsLockIsHeld() throws {
        var rules = try rules()
        #expect(rules.decide(KeyEvent(x, .down, capsHeld: true, shiftHeld: false)) == .swallow)
        #expect(rules.decide(KeyEvent(x, .up, capsHeld: true, shiftHeld: false)) == .swallow)
        #expect(rules.decide(KeyEvent(.media(7), .down, capsHeld: true, shiftHeld: false)) == .swallow)
    }

    @Test func withoutCapsLockEverythingPasses() throws {
        var rules = try rules()
        #expect(rules.decide(KeyEvent(g, .down, capsHeld: false, shiftHeld: false)) == .pass)
        #expect(rules.decide(KeyEvent(g, .down, isRepeat: true, capsHeld: false, shiftHeld: false)) == .pass)
        #expect(rules.decide(KeyEvent(g, .up, capsHeld: false, shiftHeld: false)) == .pass)
        #expect(rules.decide(KeyEvent(volumeUp, .down, capsHeld: false, shiftHeld: false)) == .pass)
    }

    @Test func capsLockLetGoFirstStillSwallowsTheKeyUpAndRepeats() throws {
        var rules = try rules()
        #expect(rules.decide(KeyEvent(g, .down, capsHeld: true, shiftHeld: false)) == .run(site))
        #expect(rules.decide(KeyEvent(caps, .up, capsHeld: false, shiftHeld: false)) == .swallow)
        #expect(rules.decide(KeyEvent(g, .down, isRepeat: true, capsHeld: false, shiftHeld: false)) == .swallow)
        #expect(rules.decide(KeyEvent(g, .up, capsHeld: false, shiftHeld: false)) == .swallow)
        #expect(rules.decide(KeyEvent(g, .down, capsHeld: false, shiftHeld: false)) == .pass)
    }

    /// A key-up missed (a password field held secure input) can't keep the key swallowed.
    @Test func aMissedKeyUpCannotStickAKey() throws {
        var rules = try rules()
        #expect(rules.decide(KeyEvent(g, .down, capsHeld: true, shiftHeld: false)) == .run(site))
        #expect(rules.decide(KeyEvent(g, .down, capsHeld: false, shiftHeld: false)) == .pass)
        #expect(rules.decide(KeyEvent(g, .up, capsHeld: false, shiftHeld: false)) == .pass)
        #expect(rules.swallowed.isEmpty)
    }

    @Test func noBindingsTouchNothing() {
        var rules = KeyRules()
        #expect(rules.decide(KeyEvent(caps, .down, capsHeld: true, shiftHeld: false)) == .pass)
        #expect(rules.decide(KeyEvent(g, .down, capsHeld: true, shiftHeld: false)) == .pass)
        #expect(rules.decide(KeyEvent(g, .up, capsHeld: false, shiftHeld: false)) == .pass)
    }

    @Test func theArrowsRunTheirMoves() throws {
        let config = try ConfigParser.parse("""
        keys:
          up: { window: top-half }
          down: { window: bottom-half }
        """)
        var rules = KeyRules(bindings: KeyRules.bindings(for: config))
        let up = KeyTrigger.key(0x7E)
        let down = KeyTrigger.key(0x7D)
        #expect(rules.decide(KeyEvent(up, .down, capsHeld: true, shiftHeld: false)) == .run(.window(.topHalf)))
        #expect(rules.decide(KeyEvent(up, .down, isRepeat: true, capsHeld: true, shiftHeld: false)) == .swallow)
        #expect(rules.decide(KeyEvent(up, .up, capsHeld: true, shiftHeld: false)) == .swallow)
        #expect(rules.decide(KeyEvent(down, .down, capsHeld: true, shiftHeld: false)) == .run(.window(.bottomHalf)))
        #expect(rules.decide(KeyEvent(down, .up, capsHeld: true, shiftHeld: false)) == .swallow)
        #expect(rules.decide(KeyEvent(up, .down, capsHeld: false, shiftHeld: false)) == .pass)
    }

    private final class Field {}

    @Test func aListeningFieldHearsKeysInsteadOfRunningThem() throws {
        var rules = try rules()
        let field = Field()
        rules.listen(ObjectIdentifier(field), hearing: .every)
        #expect(rules.isListening)
        // Bound or not, the key is heard and nothing runs.
        #expect(rules.decide(KeyEvent(g, .down, capsHeld: true, shiftHeld: false)) == .heard(g, site))
        #expect(rules.decide(KeyEvent(x, .down, capsHeld: true, shiftHeld: false)) == .heard(x, nil))
        #expect(rules.decide(KeyEvent(volumeUp, .down, capsHeld: true, shiftHeld: false)) == .heard(volumeUp, window))
        // Its repeats and key-up are swallowed as a run key's are.
        #expect(rules.decide(KeyEvent(g, .down, isRepeat: true, capsHeld: true, shiftHeld: false)) == .swallow)
        #expect(rules.decide(KeyEvent(g, .up, capsHeld: true, shiftHeld: false)) == .swallow)
        #expect(rules.decide(KeyEvent(x, .up, capsHeld: false, shiftHeld: false)) == .swallow)
        #expect(rules.decide(KeyEvent(volumeUp, .up, capsHeld: true, shiftHeld: false)) == .swallow)
        #expect(rules.swallowed.isEmpty)
        // Caps Lock itself, and keys without it, are as before.
        #expect(rules.decide(KeyEvent(caps, .down, capsHeld: true, shiftHeld: false)) == .swallow)
        #expect(rules.decide(KeyEvent(g, .down, capsHeld: false, shiftHeld: false)) == .pass)
        rules.stopListening(ObjectIdentifier(field))
        #expect(!rules.isListening)
        #expect(rules.decide(KeyEvent(g, .down, capsHeld: true, shiftHeld: false)) == .run(site))
    }

    @Test func onlyTheFieldListeningCanStop() throws {
        var rules = try rules()
        let first = Field()
        let second = Field()
        rules.listen(ObjectIdentifier(first), hearing: .every)
        rules.listen(ObjectIdentifier(second), hearing: .every)
        // The first field was replaced; its stop is late and changes nothing.
        rules.stopListening(ObjectIdentifier(first))
        #expect(rules.listener?.owner == ObjectIdentifier(second))
        #expect(rules.decide(KeyEvent(g, .down, capsHeld: true, shiftHeld: false)) == .heard(g, site))
        // Stopping with no owner ends whoever listens.
        rules.stopListening()
        #expect(!rules.isListening)
        #expect(rules.decide(KeyEvent(g, .up, capsHeld: true, shiftHeld: false)) == .swallow)
        #expect(rules.decide(KeyEvent(g, .down, capsHeld: true, shiftHeld: false)) == .run(site))
    }

    @Test func theWelcomeWindowHearsOnlyWindowAndUnboundKeys() throws {
        var rules = try rules()
        let f12 = try #require(KeyNames.triggers(for: "f12")?.first)
        let welcome = Field()
        rules.listen(ObjectIdentifier(welcome), hearing: .windowAndUnbound)
        // A site key runs, as it would anywhere.
        #expect(rules.decide(KeyEvent(g, .down, capsHeld: true, shiftHeld: false)) == .run(site))
        #expect(rules.decide(KeyEvent(g, .up, capsHeld: true, shiftHeld: false)) == .swallow)
        // A window key would move the listening window, so it is heard, with its action.
        #expect(rules.decide(KeyEvent(f12, .down, capsHeld: true, shiftHeld: false)) == .heard(f12, window))
        #expect(rules.decide(KeyEvent(f12, .up, capsHeld: true, shiftHeld: false)) == .swallow)
        // A key with nothing bound is heard, so the window can say so.
        #expect(rules.decide(KeyEvent(x, .down, capsHeld: true, shiftHeld: false)) == .heard(x, nil))
        #expect(rules.decide(KeyEvent(x, .up, capsHeld: true, shiftHeld: false)) == .swallow)
        #expect(rules.swallowed.isEmpty)
        rules.stopListening(ObjectIdentifier(welcome))
        #expect(rules.decide(KeyEvent(f12, .down, capsHeld: true, shiftHeld: false)) == .run(window))
    }

    @Test func withNoKeysBoundAListeningFieldGetsTheKeyFromItsWindow() {
        var rules = KeyRules()
        rules.listen(ObjectIdentifier(Field()), hearing: .every)
        #expect(rules.decide(KeyEvent(g, .down, capsHeld: true, shiftHeld: false)) == .pass)
    }

    @Test func aPressHeldAcrossAReloadThatDropsEveryKeyStillEndsSwallowed() throws {
        var rules = try rules()
        #expect(rules.decide(KeyEvent(g, .down, capsHeld: true, shiftHeld: false)) == .run(site))
        rules.bindings = [:]
        #expect(rules.decide(KeyEvent(g, .up, capsHeld: false, shiftHeld: false)) == .swallow)
        #expect(rules.decide(KeyEvent(g, .down, capsHeld: true, shiftHeld: false)) == .pass)
    }

    /// Caps Lock pressed with Shift held or not, then let go: what its key-up decides.
    private func press(_ rules: inout KeyRules, shift: Bool) -> KeyDecision {
        #expect(rules.decide(KeyEvent(caps, .down, capsHeld: true, shiftHeld: shift)) == .swallow)
        return rules.decide(KeyEvent(caps, .up, capsHeld: false, shiftHeld: shift))
    }

    @Test func shiftWithCapsLockSwitchesTheLockEachTime() throws {
        var rules = try rules()
        #expect(press(&rules, shift: true) == .toggleCapsLock)
        #expect(press(&rules, shift: true) == .toggleCapsLock)
        #expect(press(&rules, shift: false) == .swallow)
    }

    /// People often let go of Shift before Caps Lock; Shift counts when Caps Lock goes down.
    @Test func shiftLetGoBeforeCapsLockStillSwitches() throws {
        var rules = try rules()
        #expect(rules.decide(KeyEvent(caps, .down, capsHeld: true, shiftHeld: true)) == .swallow)
        #expect(rules.decide(KeyEvent(caps, .up, capsHeld: false, shiftHeld: false)) == .toggleCapsLock)
    }

    /// Caps Lock held, then Shift, may be the start of a shortcut: nothing switches.
    @Test func shiftPressedAfterCapsLockDoesNothing() throws {
        var rules = try rules()
        #expect(rules.decide(KeyEvent(caps, .down, capsHeld: true, shiftHeld: false)) == .swallow)
        #expect(rules.decide(KeyEvent(caps, .up, capsHeld: false, shiftHeld: true)) == .swallow)
    }

    @Test func shiftAndCapsLockWithAKeyRunOnlyTheKey() throws {
        var rules = try rules()
        #expect(rules.decide(KeyEvent(caps, .down, capsHeld: true, shiftHeld: true)) == .swallow)
        #expect(rules.decide(KeyEvent(g, .down, capsHeld: true, shiftHeld: true)) == .run(site))
        #expect(rules.decide(KeyEvent(g, .up, capsHeld: true, shiftHeld: true)) == .swallow)
        #expect(rules.decide(KeyEvent(caps, .up, capsHeld: false, shiftHeld: true)) == .swallow)
        // A top-row key counts as a key too.
        #expect(rules.decide(KeyEvent(caps, .down, capsHeld: true, shiftHeld: true)) == .swallow)
        #expect(rules.decide(KeyEvent(volumeUp, .down, capsHeld: true, shiftHeld: true)) == .run(window))
        #expect(rules.decide(KeyEvent(caps, .up, capsHeld: false, shiftHeld: true)) == .swallow)
        #expect(rules.decide(KeyEvent(volumeUp, .up, capsHeld: false, shiftHeld: true)) == .swallow)
    }

    @Test func capsLockRepeatsSwitchTheLockOnce() throws {
        var rules = try rules()
        #expect(rules.decide(KeyEvent(caps, .down, capsHeld: true, shiftHeld: true)) == .swallow)
        #expect(rules.decide(KeyEvent(caps, .down, isRepeat: true, capsHeld: true, shiftHeld: true)) == .swallow)
        #expect(rules.decide(KeyEvent(caps, .down, isRepeat: true, capsHeld: true, shiftHeld: true)) == .swallow)
        #expect(rules.decide(KeyEvent(caps, .up, capsHeld: false, shiftHeld: true)) == .toggleCapsLock)
    }

    /// A press whose key-up was missed (the tap was switched off a moment) is dropped, and
    /// the next press decides by its own Shift; a key-up whose key-down was missed switches
    /// nothing.
    @Test func aMissedCapsLockKeyUpOrKeyDownSwitchesNothing() throws {
        var rules = try rules()
        #expect(rules.decide(KeyEvent(caps, .down, capsHeld: true, shiftHeld: true)) == .swallow)
        #expect(press(&rules, shift: false) == .swallow)
        #expect(press(&rules, shift: true) == .toggleCapsLock)
        #expect(rules.decide(KeyEvent(caps, .up, capsHeld: false, shiftHeld: true)) == .swallow)
    }

    @Test func shiftWithCapsLockSwitchesTheLockWhileAFieldListens() throws {
        var rules = try rules()
        rules.listen(ObjectIdentifier(Field()), hearing: .every)
        #expect(press(&rules, shift: true) == .toggleCapsLock)
    }

    /// With no keys bound Caps Lock is macOS's own, and its own press switches the lock.
    @Test func withNoKeysBoundShiftWithCapsLockIsMacOSsOwn() {
        var rules = KeyRules()
        #expect(rules.decide(KeyEvent(caps, .down, capsHeld: true, shiftHeld: true)) == .pass)
        #expect(rules.decide(KeyEvent(caps, .up, capsHeld: false, shiftHeld: true)) == .pass)
    }
}

@Suite struct WindowLayoutTests {
    // A 1728x1117 primary screen with a 25pt menu bar and a 70pt Dock at the bottom, and a
    // 1920x1080 screen to its right, top-aligned.
    private let primary = CGRect(x: 0, y: 0, width: 1728, height: 1117)
    private let primaryVisible = CGRect(x: 0, y: 70, width: 1728, height: 1022)
    private let second = CGRect(x: 1728, y: 37, width: 1920, height: 1080)
    private let secondVisible = CGRect(x: 1728, y: 37, width: 1920, height: 1055)

    @Test func halvesAndMaximizeOnThePrimaryScreen() {
        #expect(WindowLayout.frame(.leftHalf, visible: primaryVisible, primaryHeight: 1117) == CGRect(x: 0, y: 25, width: 864, height: 1022))
        #expect(WindowLayout.frame(.rightHalf, visible: primaryVisible, primaryHeight: 1117) == CGRect(x: 864, y: 25, width: 864, height: 1022))
        #expect(WindowLayout.frame(.maximize, visible: primaryVisible, primaryHeight: 1117) == CGRect(x: 0, y: 25, width: 1728, height: 1022))
    }

    @Test func anOddWidthGivesTheExtraPointToTheRight() {
        let visible = CGRect(x: 0, y: 0, width: 1001, height: 500)
        #expect(WindowLayout.frame(.leftHalf, visible: visible, primaryHeight: 500).width == 500)
        #expect(WindowLayout.frame(.rightHalf, visible: visible, primaryHeight: 500) == CGRect(x: 500, y: 0, width: 501, height: 500))
    }

    @Test func topAndBottomHalvesOnThePrimaryScreen() {
        #expect(WindowLayout.frame(.topHalf, visible: primaryVisible, primaryHeight: 1117) == CGRect(x: 0, y: 25, width: 1728, height: 511))
        #expect(WindowLayout.frame(.bottomHalf, visible: primaryVisible, primaryHeight: 1117) == CGRect(x: 0, y: 536, width: 1728, height: 511))
    }

    @Test func anOddHeightGivesTheExtraPointToTheBottomWithNoGap() {
        let visible = CGRect(x: 0, y: 0, width: 800, height: 501)
        let top = WindowLayout.frame(.topHalf, visible: visible, primaryHeight: 501)
        let bottom = WindowLayout.frame(.bottomHalf, visible: visible, primaryHeight: 501)
        #expect(top == CGRect(x: 0, y: 0, width: 800, height: 250))
        #expect(bottom == CGRect(x: 0, y: 250, width: 800, height: 251))
        #expect(top.maxY == bottom.minY)
    }

    @Test func aSecondScreenUsesItsOwnFrame() {
        #expect(WindowLayout.frame(.leftHalf, visible: secondVisible, primaryHeight: 1117) == CGRect(x: 1728, y: 25, width: 960, height: 1055))
        #expect(WindowLayout.frame(.topHalf, visible: secondVisible, primaryHeight: 1117) == CGRect(x: 1728, y: 25, width: 1920, height: 527))
        #expect(WindowLayout.frame(.bottomHalf, visible: secondVisible, primaryHeight: 1117) == CGRect(x: 1728, y: 552, width: 1920, height: 528))
    }

    @Test func theWindowStaysOnTheScreenHoldingMostOfIt() {
        let screens = [primary, second]
        // Accessibility frames: top-left origin.
        #expect(WindowLayout.screen(holding: CGRect(x: 100, y: 100, width: 800, height: 600), screens: screens, primaryHeight: 1117) == 0)
        #expect(WindowLayout.screen(holding: CGRect(x: 1600, y: 100, width: 800, height: 600), screens: screens, primaryHeight: 1117) == 1)
        #expect(WindowLayout.screen(holding: CGRect(x: 1300, y: 100, width: 800, height: 600), screens: screens, primaryHeight: 1117) == 0)
        #expect(WindowLayout.screen(holding: CGRect(x: 9000, y: 9000, width: 10, height: 10), screens: screens, primaryHeight: 1117) == 0)
    }

    @Test func flippingTwiceIsTheSameRect() {
        let rect = CGRect(x: 10, y: 20, width: 300, height: 400)
        #expect(WindowLayout.flip(WindowLayout.flip(rect, primaryHeight: 1117), primaryHeight: 1117) == rect)
    }
}
