import Foundation

// swiftlint:disable type_name

/// Possible key code values for `NSEvent.keyCode` - taken from <HIToolbox/Events.h>.
@objc
public enum EventKeyCode: UInt16, RawRepresentable {
    case `return`                    = 0x24
    case tab                       = 0x30
    case space                     = 0x31
    case delete                    = 0x33
    case escape                    = 0x35
    case command                   = 0x37
    case shift                     = 0x38
    case capsLock                  = 0x39
    case option                    = 0x3A
    case control                   = 0x3B
    case rightShift                = 0x3C
    case rightOption               = 0x3D
    case rightControl              = 0x3E
    case function                  = 0x3F
    case f17                       = 0x40
    case volumeUp                  = 0x48
    case volumeDown                = 0x49
    case mute                      = 0x4A
    case f18                       = 0x4F
    case f19                       = 0x50
    case f20                       = 0x5A
    case f5                        = 0x60
    case f6                        = 0x61
    case f7                        = 0x62
    case f3                        = 0x63
    case f8                        = 0x64
    case f9                        = 0x65
    case f11                       = 0x67
    case f13                       = 0x69
    case f16                       = 0x6A
    case f14                       = 0x6B
    case f10                       = 0x6D
    case f12                       = 0x6F
    case f15                       = 0x71
    case help                      = 0x72
    case home                      = 0x73
    case pageUp                    = 0x74
    case forwardDelete             = 0x75
    case f4                        = 0x76
    case end                       = 0x77
    case f2                        = 0x78
    case pageDown                  = 0x79
    case f1                        = 0x7A
    case leftArrow                 = 0x7B
    case rightArrow                = 0x7C
    case downArrow                 = 0x7D
    case upArrow                   = 0x7E

    // Pilot Additions
    case enter                     = 0x4C
    case unknown                   = 0x0
}

public extension NSEvent {

    /// Returns a semantic `EventKeyCode` value (or .Unknown) for the target event.
    public var eventKeyCode: EventKeyCode {
        return EventKeyCode(rawValue: keyCode) ?? .unknown
    }
}
