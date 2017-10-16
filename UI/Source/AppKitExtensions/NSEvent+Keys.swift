import Foundation
import Pilot

public extension NSEvent {

    /// Returns a semantic `EventKeyCode` value (or .Unknown) for the target event.
    public var eventKeyCode: EventKeyCode {
        return EventKeyCode(rawValue: keyCode) ?? .unknown
    }

    public var eventKeyModifierFlags: EventKeyModifierFlags {
        return modifierFlags.eventKeyModifierFlags
    }
}

extension NSEvent.ModifierFlags {
    public var eventKeyModifierFlags: EventKeyModifierFlags {
        var result = EventKeyModifierFlags(rawValue: 0)
        if contains(.capsLock) {
            result.formUnion(.capsLock)
        }
        if contains(.command) {
            result.formUnion(.command)
        }
        if contains(.control) {
            result.formUnion(.control)
        }
        if contains(.function) {
            result.formUnion(.function)
        }
        if contains(.option) {
            result.formUnion(.option)
        }
        if contains(.shift) {
            result.formUnion(.shift)
        }
        return result
    }
}

extension EventKeyModifierFlags {
    public var modifierFlags: NSEvent.ModifierFlags {
        var result = NSEvent.ModifierFlags(rawValue: 0)
        if contains(.capsLock) {
            result.formUnion(.capsLock)
        }
        if contains(.command) {
            result.formUnion(.command)
        }
        if contains(.control) {
            result.formUnion(.control)
        }
        if contains(.function) {
            result.formUnion(.function)
        }
        if contains(.option) {
            result.formUnion(.option)
        }
        if contains(.shift) {
            result.formUnion(.shift)
        }
        return result
    }
}
