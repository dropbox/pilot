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

extension ModelVersion: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int

    public init(integerLiteral value: IntegerLiteralType) {
        self.hash1 = UInt64(bitPattern: Int64(value))
        self.hash2 = 0
    }
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

    public mutating func mix(_ value: UInt32) {
        Hasher_Mix_UInt32(&hasher, value)
    }

    public mutating func mix(_ value: UInt16) {
        Hasher_Mix_UInt16(&hasher, value)
    }

    public mutating func mix(_ value: UInt8) {
        Hasher_Mix_UInt8(&hasher, value)
    }

    public mutating func mix(_ value: UInt) {
        if MemoryLayout<UInt>.size == MemoryLayout<UInt32>.size {
            mix(UInt32(value))
        } else {
            mix(UInt64(value))
        }
    }

    public mutating func mix(_ value: Int64) {
        Hasher_Mix_Int64(&hasher, value)
    }

    public mutating func mix(_ value: Int32) {
        Hasher_Mix_Int32(&hasher, value)
    }

    public mutating func mix(_ value: Int16) {
        Hasher_Mix_Int16(&hasher, value)
    }

    public mutating func mix(_ value: Int8) {
        Hasher_Mix_Int8(&hasher, value)
    }

    public mutating func mix(_ value: Int) {
        if MemoryLayout<Int>.size == MemoryLayout<Int32>.size {
            mix(Int32(value))
        } else {
            mix(Int64(value))
        }
    }

    public mutating func mix(_ value: Float) {
        mix(value.bitPattern)
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

    private var hasher = Hasher(internal: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
}

// MARK: ModelVersionMixer Encoder conformance

extension ModelVersionMixer: Encoder {
    /// Generate a version based on the serialization of an Encodable
    public static func version(_ value: Encodable) -> ModelVersion {
        var mixer = ModelVersionMixer()
        // Encoders in general can throw, but ModelVersionMixer never does.
        try? value.encode(to: mixer)
        return mixer.result()
    }

    public var codingPath: [CodingKey] { return [] }
    public var userInfo: [CodingUserInfoKey : Any] { return [:] }

    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {

        return KeyedEncodingContainer(ModelVersionKeyedEncoder(ModelVersionEncoder(mixer: self)))
    }

    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        return ModelVersionEncoder(mixer: self)
    }

    public func singleValueContainer() -> SingleValueEncodingContainer {
        return ModelVersionEncoder(mixer: self)
    }
}

private class ModelVersionEncoder {
    public enum Marker: UInt8 {
        case None

        case Nil
        case Bool
        case Int
        case Int8
        case Int16
        case Int32
        case Int64
        case UInt
        case UInt8
        case UInt16
        case UInt32
        case UInt64
        case Float
        case Double
        case String

        case KeyedContainerBegin
        case KeyedContainerEnd
        case UnkeyedContainerBegin
        case UnkeyedContainerEnd
        case SingleValueContainerBegin
        case SingleValueContainerEnd
    }

    public init(mixer: ModelVersionMixer) {
        self.mixer = mixer
    }

    private func mix(marker: Marker) {
        if closeContainerMarker != .None {
            mix(marker: closeContainerMarker)
            closeContainerMarker = .None
        }
        mixer.mix(marker.rawValue)
    }

    private var mixer: ModelVersionMixer
    private var closeContainerMarker: Marker = .None
}

extension ModelVersionEncoder: Encoder {
    public var codingPath: [CodingKey] { return [] }
    public var userInfo: [CodingUserInfoKey : Any] { return [:] }

    private var newEncoder: ModelVersionEncoder {
        return ModelVersionEncoder(mixer: mixer)
    }

    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        mix(marker: .KeyedContainerBegin)
        closeContainerMarker = .KeyedContainerEnd
        return KeyedEncodingContainer(ModelVersionKeyedEncoder<Key>(newEncoder))
    }

    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        mix(marker: .UnkeyedContainerBegin)
        closeContainerMarker = .UnkeyedContainerEnd
        return newEncoder
    }

    public func singleValueContainer() -> SingleValueEncodingContainer {
        mix(marker: .SingleValueContainerBegin)
        closeContainerMarker = .SingleValueContainerEnd
        return newEncoder
    }
}

extension ModelVersionEncoder: SingleValueEncodingContainer {
    public func encodeNil() throws {
        mix(marker: .Nil)
    }

    public func encode(_ value: Bool) throws {
        mix(marker: .Bool)
        mixer.mix(value)
    }

    public func encode(_ value: Int) throws {
        mix(marker: .Int)
        mixer.mix(value)
    }

    public func encode(_ value: Int8) throws {
        mix(marker: .Int8)
        mixer.mix(value)
    }

    public func encode(_ value: Int16) throws {
        mix(marker: .Int16)
        mixer.mix(value)
    }

    public func encode(_ value: Int32) throws {
        mix(marker: .Int32)
        mixer.mix(value)
    }

    public func encode(_ value: Int64) throws {
        mix(marker: .Int64)
        mixer.mix(value)
    }

    public func encode(_ value: UInt) throws {
        mix(marker: .UInt)
        mixer.mix(value)
    }

    public func encode(_ value: UInt8) throws {
        mix(marker: .UInt8)
        mixer.mix(value)
    }

    public func encode(_ value: UInt16) throws {
        mix(marker: .UInt16)
        mixer.mix(value)
    }

    public func encode(_ value: UInt32) throws {
        mix(marker: .UInt32)
        mixer.mix(value)
    }

    public func encode(_ value: UInt64) throws {
        mix(marker: .UInt64)
        mixer.mix(value)
    }

    public func encode(_ value: Float) throws {
        mix(marker: .Float)
        mixer.mix(value)
    }

    public func encode(_ value: Double) throws {
        mix(marker: .Double)
        mixer.mix(value)
    }

    public func encode(_ value: String) throws {
        mix(marker: .String)
        mixer.mix(value.count)
        mixer.mix(value)
    }

    public func encode<T>(_ value: T) throws where T : Encodable {
        try value.encode(to: self)
    }
}

extension ModelVersionEncoder: UnkeyedEncodingContainer {
    public var count: Int { return 0 }

    public func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {

        return container(keyedBy: NestedKey.self)
    }

    public func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return unkeyedContainer()
    }

    public func superEncoder() -> Encoder {
        return self
    }
}

private struct ModelVersionKeyedEncoder<K: CodingKey>: KeyedEncodingContainerProtocol {
    public typealias Key = K

    public init(_ encoder: ModelVersionEncoder) {
        self.encoder = encoder
    }

    public var codingPath: [CodingKey] {
        return []
    }

    public func encodeNil(forKey key: K) throws {
        try encoder.encode(key.stringValue)
        try encoder.encodeNil()
    }

    public func encode(_ value: Bool, forKey key: K) throws {
        try encoder.encode(key.stringValue)
        try encoder.encode(value)
    }

    public func encode(_ value: Int, forKey key: K) throws {
        try encoder.encode(key.stringValue)
        try encoder.encode(value)
    }

    public func encode(_ value: Int8, forKey key: K) throws {
        try encoder.encode(key.stringValue)
        try encoder.encode(value)
    }

    public func encode(_ value: Int16, forKey key: K) throws {
        try encoder.encode(key.stringValue)
        try encoder.encode(value)
    }

    public func encode(_ value: Int32, forKey key: K) throws {
        try encoder.encode(key.stringValue)
        try encoder.encode(value)
    }

    public func encode(_ value: Int64, forKey key: K) throws {
        try encoder.encode(key.stringValue)
        try encoder.encode(value)
    }

    public func encode(_ value: UInt, forKey key: K) throws {
        try encoder.encode(key.stringValue)
        try encoder.encode(value)
    }

    public func encode(_ value: UInt8, forKey key: K) throws {
        try encoder.encode(key.stringValue)
        try encoder.encode(value)
    }

    public func encode(_ value: UInt16, forKey key: K) throws {
        try encoder.encode(key.stringValue)
        try encoder.encode(value)
    }

    public func encode(_ value: UInt32, forKey key: K) throws {
        try encoder.encode(key.stringValue)
        try encoder.encode(value)
    }

    public func encode(_ value: UInt64, forKey key: K) throws {
        try encoder.encode(key.stringValue)
        try encoder.encode(value)
    }

    public func encode(_ value: Float, forKey key: K) throws {
        try encoder.encode(key.stringValue)
        try encoder.encode(value)
    }

    public func encode(_ value: Double, forKey key: K) throws {
        try encoder.encode(key.stringValue)
        try encoder.encode(value)
    }

    public func encode(_ value: String, forKey key: K) throws {
        try encoder.encode(key.stringValue)
        try encoder.encode(value)
    }

    public func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
        try encoder.encode(key.stringValue)
        try encoder.encode(value)
    }

    public func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {

        try? encoder.encode(key.stringValue)
        return encoder.container(keyedBy: NestedKey.self)
    }

    public func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        try? encoder.encode(key.stringValue)
        return encoder.unkeyedContainer()
    }

    public func superEncoder() -> Encoder {
        return encoder
    }

    public func superEncoder(forKey key: K) -> Encoder {
        try? encoder.encode(key.stringValue)
        return encoder
    }

    private var encoder: ModelVersionEncoder
}
