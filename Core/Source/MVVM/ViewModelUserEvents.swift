import Foundation

/// Event types that view models may handle, typically sent from the view layer.
public enum ViewModelUserEvent {
    /// On mouse-supporting platforms, represents a click by the user.
    case click

    /// Represents the user typing a key with modifier flags.
    case keyDown(EventKeyCode, EventKeyModifierFlags)

    /// Reprsents the user performing a long-press on the target view model.
    case longPress

    /// On mouse-supporting platforms, represents a secondary (right) click by the user.
    case secondaryClick

    /// On any platform, represents the target being selected (via mouse, programatically, or tap).
    case select

    /// On touch platforms, represents the target receiving a single tap.
    case tap
}

/// Simple wrapper around NSEvent.ModifierFlags to avoid importing AppKit.
public struct EventKeyModifierFlags: OptionSet {

    // MARK: OptionSet

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public let rawValue: UInt

    // MARK: Values

    /// Set if Caps Lock key is pressed.
    public static var capsLock = EventKeyModifierFlags(rawValue: 1<<0)
    /// Set if Shift key is pressed.
    public static var shift = EventKeyModifierFlags(rawValue: 1<<1)
    /// Set if Control key is pressed.
    public static var control = EventKeyModifierFlags(rawValue: 1<<2)
    /// Set if Option or Alternate key is pressed.
    public static var option = EventKeyModifierFlags(rawValue: 1<<3)
    /// Set if Command key is pressed.
    public static var command = EventKeyModifierFlags(rawValue: 1<<4)
    /// Set if Function key is pressed.
    public static var function = EventKeyModifierFlags(rawValue: 1<<5)
}

extension ViewModelUserEvent: Hashable {
    public var hashValue: Int {
        switch self {
        case .click:
            return 1<<0
        case .keyDown(let key, let flags):
            return "keyDown-\(key)-\(flags)".hashValue
        case .longPress:
            return 1<<1
        case .secondaryClick:
            return 1<<2
        case .select:
            return 1<<3
        case .tap:
            return 1<<4
        }
    }

    public static func ==(lhs: ViewModelUserEvent, rhs: ViewModelUserEvent) -> Bool {
        switch (lhs, rhs) {
        case (.click, .click), (.longPress, .longPress), (.secondaryClick, .secondaryClick), (.select, .select),
             (.tap, .tap):
            return true
        case (.keyDown(let lKey, let lModifiers), .keyDown(let rKey, let rModifiers)):
            return lKey == rKey && lModifiers == rModifiers
        case (.click, _), (.longPress, _), (.secondaryClick, _), (.select, _), (.tap, _), (.keyDown, _):
            return false
        }
    }

    public static var spaceKey = ViewModelUserEvent.keyDown(.space, [])
    public static var enterKey = ViewModelUserEvent.keyDown(.enter, [])
}

// swiftlint:disable type_name

/// Possible key code values for `NSEvent.keyCode` - taken from <HIToolbox/Events.h>.
@objc
public enum EventKeyCode: UInt16, RawRepresentable {
    case `return`                  = 0x24
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
    case A                         = 0x00
    case S                         = 0x01
    case D                         = 0x02
    case F                         = 0x03
    case H                         = 0x04
    case G                         = 0x05
    case Z                         = 0x06
    case X                         = 0x07
    case C                         = 0x08
    case V                         = 0x09
    case B                         = 0x0B
    case Q                         = 0x0C
    case W                         = 0x0D
    case E                         = 0x0E
    case R                         = 0x0F
    case Y                         = 0x10
    case T                         = 0x11
    case one                       = 0x12
    case two                       = 0x13
    case three                     = 0x14
    case four                      = 0x15
    case six                       = 0x16
    case five                      = 0x17
    case Equal                     = 0x18
    case nine                      = 0x19
    case seven                     = 0x1A
    case Minus                     = 0x1B
    case eight                     = 0x1C
    case zero                      = 0x1D
    case RightBracket              = 0x1E
    case O                         = 0x1F
    case U                         = 0x20
    case LeftBracket               = 0x21
    case I                         = 0x22
    case P                         = 0x23
    case L                         = 0x25
    case J                         = 0x26
    case Quote                     = 0x27
    case K                         = 0x28
    case Semicolon                 = 0x29
    case Backslash                 = 0x2A
    case Comma                     = 0x2B
    case Slash                     = 0x2C
    case N                         = 0x2D
    case M                         = 0x2E
    case Period                    = 0x2F
    case Grave                     = 0x32
    case KeypadDecimal             = 0x41
    case KeypadMultiply            = 0x43
    case KeypadPlus                = 0x45
    case KeypadClear               = 0x47
    case KeypadDivide              = 0x4B
    case KeypadMinus               = 0x4E
    case KeypadEquals              = 0x51
    case Keypad0                   = 0x52
    case Keypad1                   = 0x53
    case Keypad2                   = 0x54
    case Keypad3                   = 0x55
    case Keypad4                   = 0x56
    case Keypad5                   = 0x57
    case Keypad6                   = 0x58
    case Keypad7                   = 0x59
    case Keypad8                   = 0x5B
    case Keypad9                   = 0x5C


    // Pilot Additions
    case enter                     = 0x4C
    case unknown                   = 0xFF
}
