import Foundation
import Pilot

#if swift(>=4)
public typealias AppKitEventModifierFlags = NSEvent.ModifierFlags
#else
public typealias AppKitEventModifierFlags = NSEventModifierFlags
#endif

public extension NSEvent {

    /// Returns a semantic `EventKeyCode` value (or .Unknown) for the target event.
    public var eventKeyCode: EventKeyCode {
        return EventKeyCode(rawValue: keyCode) ?? .unknown
    }

    public var eventKeyModifierFlags: EventKeyModifierFlags {
        return modifierFlags.eventKeyModifierFlags
    }
}

extension AppKitEventModifierFlags {
    public var eventKeyModifierFlags: EventKeyModifierFlags {
        var result = EventKeyModifierFlags(rawValue: 0)
        if contains(NSEvent.ModifierFlags.capsLock) {
            result.formUnion(.capsLock)
        }
        if contains(NSEvent.ModifierFlags.command) {
            result.formUnion(.command)
        }
        if contains(NSEvent.ModifierFlags.control) {
            result.formUnion(.control)
        }
        if contains(NSEvent.ModifierFlags.function) {
            result.formUnion(.function)
        }
        if contains(NSEvent.ModifierFlags.option) {
            result.formUnion(.option)
        }
        if contains(NSEvent.ModifierFlags.shift) {
            result.formUnion(.shift)
        }
        return result
    }
}

extension EventKeyModifierFlags {
    public var modifierFlags: AppKitEventModifierFlags {
        var result = AppKitEventModifierFlags(rawValue: 0)
        if contains(.capsLock) {
            result.formUnion(NSEvent.ModifierFlags.capsLock)
        }
        if contains(.command) {
            result.formUnion(NSEvent.ModifierFlags.command)
        }
        if contains(.control) {
            result.formUnion(NSEvent.ModifierFlags.control)
        }
        if contains(.function) {
            result.formUnion(NSEvent.ModifierFlags.function)
        }
        if contains(.option) {
            result.formUnion(NSEvent.ModifierFlags.option)
        }
        if contains(.shift) {
            result.formUnion(NSEvent.ModifierFlags.shift)
        }
        return result
    }
}
