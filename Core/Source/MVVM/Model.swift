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

/// 128-bit value that represents the version of the data in a model.
/// Do not assume these values are identical across runs of the program.
public struct ModelVersion: Equatable {
    public init(_ value: Int64) {
        self.hash1 = UInt64(bitPattern: value)
        self.hash2 = 0
    }

    public init(_ value: UInt64) {
        self.hash1 = value
        self.hash2 = 0
    }

    public init(fromString value: String) {
        // TODO(ca): SpookyHash has a function for computing hashes in one go.
        // It's a bit more efficient than using ModelVersionMixer.
        var mixer = ModelVersionMixer()
        mixer.mix(value)
        self = mixer.result()
    }

    public init(hash1: UInt64, hash2: UInt64) {
        self.hash1 = hash1
        self.hash2 = hash2
    }

    /// Returns a constant version number used in Models whose contents
    /// never change.
    public static var unit: ModelVersion {
        return ModelVersion(UInt64(0))
    }

    /// Returns a version unique across this run of the program.
    public static func makeUnique() -> ModelVersion {
        return ModelVersion(Token.makeUnique().rawValue)
    }

    fileprivate let hash1: UInt64
    fileprivate let hash2: UInt64
}

public func ==(lhs: ModelVersion, rhs: ModelVersion) -> Bool {
    return lhs.hash1 == rhs.hash1 && lhs.hash2 == rhs.hash2
}

/// Uses a non-cryptographic, but collision-resistant hash (with good mixing) to
/// produce a unique ModelVersion given a set of values mixed in.
public struct ModelVersionMixer {

    // MARK: Init

    public init() {
        Hasher_Init(&hasher)
    }

    // TODO(ca): If/When Swift gets constrained protocol instances, implement a Mixable protocol.

    // MARK: Mixing Functions

    public mutating func mix(_ value: ModelVersion) {
        Hasher_Mix_UInt64_2(&hasher, value.hash1, value.hash2)
    }

    public mutating func mix(_ value: UInt64) {
        Hasher_Mix_UInt64(&hasher, value)
    }

    public mutating func mix(_ value: Int64) {
        Hasher_Mix_Int64(&hasher, value)
    }

    public mutating func mix(_ value: Int32) {
        Hasher_Mix_Int32(&hasher, value)
    }

    public mutating func mix(_ value: Int) {
        if MemoryLayout<Int>.size == 4 {
            mix(Int32(value))
        } else {
            mix(Int64(value))
        }
    }

    public mutating func mix(_ value: Double) {
        mix(value.bitPattern)
    }

    public mutating func mix(_ value: String?) {
        switch value {
        case .none:
            mix(false)
        case .some(let s):
            mix(true)
            mix(s)
        }
    }

    public mutating func mix(_ value: Bool) {
        Hasher_Mix_UInt8(&hasher, value ? 1 : 0)
    }

    public mutating func mix(_ value: String) {
        // We need a canonical representation of the String that's cheaply accessible.  String has three storage
        // modes: latin-1, UTF-16, and NSString.  UTF-16 is the fastest canonical storage.

        // This is not at all the fastest way to add a bunch of data to the hasher, but how is the underlying storage
        // accessible in Swift?
        for codeUnit in value.utf16 {
            Hasher_Mix_UInt16(&hasher, codeUnit)
        }

        // mikeash on freenode #swift-lang says there's probably no current way to get access to the underlying
        // UTF-16 buffer but:
        // <mikeash> chadaustin: don't think so, you can easily get an array of them which you can then
        //     pass as a pointer by doing Array(string.utf16), but that'll make a copy
        // <chadaustin> mikeash, well, that's worth benchmarking against iterating across the utf-16 code
        //     units :) thanks!
    }

    // MARK: Result Retrieval

    /// Retrieve the 128-bit output hash given the data mixed in so far.
    public mutating func result() -> ModelVersion {
        // Ideally this would be a computed property named `result` but Swift doesn't allow
        // taking the address of a property from within a computed property, and computed
        // properties can't be marked mutating.  (In reality, Hasher_Final is const in its hasher
        // so it's not really mutating.  This is just a Swift limitation.)

        var hash1: UInt64 = 0
        var hash2: UInt64 = 0

        Hasher_Final(&hasher, &hash1, &hash2)

        return ModelVersion(hash1: hash1, hash2: hash2)
    }

    private var hasher = Hasher()
}
