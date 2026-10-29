// The system's key mapping that turns Caps Lock into F18, through the HID event system's
// public property (what `hidutil property --set` drives). Only CapsJump's own entry is
// ever added or removed, so a mapping someone else set survives. The mapping lasts until
// it is removed or the Mac restarts, so the app removes it whenever it quits. Taking Caps
// Lock also switches its lock off, since once mapped Caps Lock alone can no longer switch
// it off. From then on Shift + Caps Lock switches the lock (`toggleLock`), and mapping
// again when the config is read leaves it alone, so saving the config doesn't undo it.

import CapsJumpCore
import Foundation
import IOKit.hidsystem

public enum KeyMapping {
    private static let source = "HIDKeyboardModifierMappingSrc"
    private static let destination = "HIDKeyboardModifierMappingDst"

    /// Whether Caps Lock is mapped to F18 now.
    public static func isInPlace() -> Bool {
        entries(client()).contains(where: isOurs)
    }

    /// Maps Caps Lock to F18, or removes CapsJump's entry. False when the system refused
    /// the change.
    @discardableResult
    public static func apply(_ takeCapsLock: Bool) -> Bool {
        let client = client()
        let before = entries(client)
        var after = before.filter { !isOurs($0) }
        if takeCapsLock {
            after.append([source: NSNumber(value: CapsLock.usage), destination: NSNumber(value: CapsLock.targetUsage)])
            if !before.contains(where: isOurs) { unlockCapsLock() }
        }
        guard (after as NSArray) != (before as NSArray) else { return true }
        return IOHIDEventSystemClientSetProperty(client, kIOHIDUserKeyUsageMapKey as CFString, after as CFArray)
    }

    /// Switches the Caps Lock lock to its other state, as pressing the key would without
    /// the mapping: the state it is in now, or nil when the system refused. Whether it was
    /// on is asked of the system each time, never remembered.
    public static func toggleLock() -> Bool? {
        withHIDSystem { connect in
            var locked = false
            guard IOHIDGetModifierLockState(connect, Int32(kIOHIDCapsLockState), &locked) == KERN_SUCCESS,
                  IOHIDSetModifierLockState(connect, Int32(kIOHIDCapsLockState), !locked) == KERN_SUCCESS
            else { return nil }
            return !locked
        }
    }

    /// Switches the Caps Lock lock off, as pressing the key would.
    private static func unlockCapsLock() {
        withHIDSystem { connect in
            var locked = false
            if IOHIDGetModifierLockState(connect, Int32(kIOHIDCapsLockState), &locked) == KERN_SUCCESS, locked {
                IOHIDSetModifierLockState(connect, Int32(kIOHIDCapsLockState), false)
            }
        }
    }

    /// Runs `body` with a connection to the HID system, or returns nil without one.
    private static func withHIDSystem<T>(_ body: (io_connect_t) -> T?) -> T? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching(kIOHIDSystemClass))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        var connect: io_connect_t = 0
        guard IOServiceOpen(service, mach_task_self_, UInt32(kIOHIDParamConnectType), &connect) == KERN_SUCCESS else { return nil }
        defer { IOServiceClose(connect) }
        return body(connect)
    }

    private static func client() -> IOHIDEventSystemClient {
        IOHIDEventSystemClientCreateSimpleClient(kCFAllocatorDefault)
    }

    private static func entries(_ client: IOHIDEventSystemClient) -> [[String: Any]] {
        IOHIDEventSystemClientCopyProperty(client, kIOHIDUserKeyUsageMapKey as CFString) as? [[String: Any]] ?? []
    }

    private static func isOurs(_ entry: [String: Any]) -> Bool {
        guard let source = (entry[source] as? NSNumber)?.uint64Value,
              let destination = (entry[destination] as? NSNumber)?.uint64Value
        else { return false }
        return CapsLock.isMapping(source: source, destination: destination)
    }
}
