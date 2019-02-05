import Foundation

public typealias ModelId = String

/// Core protocol which represents a single model item. Typically, model items in Pilot have value-type semantics. If
/// the implementation is a reference-type, it should use internal copy-on-write techniques to provide external
/// value-type semantics.
///
/// This protocol is a very basic building block which is expanded upon by other higher-level protocols and components
/// e.g. `ModelCollection`.
public protocol Model {
    /// Returns a unique identifier for the model item.  Represents the logical object, like a specific user or room.
    var modelId: ModelId { get }

    /// Represents the version of the data associated with this model.  If the version of two model objects is the same,
    /// the data behind the model will be the same.  (If the version changes, binding layers will know that the
    /// `ViewModel` and `View` should update.)
    var modelVersion: ModelVersion { get }
}

/// Swift 4.2+ Hasher-computed value that represents the version of the data in a model.
/// Do not assume these values are identical across runs of the program.
public struct ModelVersion: Equatable, Hashable {

    public init(fromString value: String) {
        var hasher = Hasher()
        hasher.combine(value)
        hash = hasher.finalize()
    }

    public init(hash: Int) {
        self.hash = hash
    }

    /// Returns a constant version number used in Models whose contents
    /// never change.
    public static var unit: ModelVersion {
        return ModelVersion(hash: 0)
    }

    /// Returns a version unique across this run of the program.
    public static func makeUnique() -> ModelVersion {
        // On 32bit CPUs, this will *potentially, rarely, in the case of generating tons of tokens* be problematic.
        // Token gives back an Int64 which on 32bit platforms when cast to Int could overflow. This is not a factor
        // on iOS 11+ as that OS supports 64bit CPUs only and isn't a factor on macOS 10.7+.
        return ModelVersion(hash: Int(Token.makeUnique().rawValue))
    }

    fileprivate let hash: Int
}

extension ModelVersion: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int

    public init(integerLiteral value: IntegerLiteralType) {
        self.hash = value
    }
}
