import Foundation
import libkern

/// A unique value for use as an opaque token.  Commonly used as the key for observer lists.
public struct Token: Hashable, Equatable {

    // MARK: Public

    /// Returns a new token guaranteed to be unique.  Can safely be called from multiple threads.
    public static func makeUnique() -> Token {
        return Token(OSAtomicIncrement64(&nextValue))
    }

    /// A dummy sentinel value, intended for situations where it will never be used.
    public static var dummy: Token {
        return Token(-1)
    }

    public var rawValue: Int64 {
        return value
    }

    public var stringValue: String {
        return String(value)
    }

    // MARK: Private

    private init(_ value: Int64) {
        self.value = value
    }

    private let value: Int64

    // If we created tokens once per nanosecond (impossible), it would take almost 300 years to overflow
    private static var nextValue: Int64 = 0

    // MARK: Equatable

    public static func == (lhs: Token, rhs: Token) -> Bool {
        return lhs.value == rhs.value
    }
}
