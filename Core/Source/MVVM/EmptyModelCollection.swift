import Foundation

/// Convenience implementation of `ModelCollection` which is completely empty.
public final class EmptyModelCollection: ModelCollection {

    // MARK: Init

    public init() {}

    // MARK: ModelCollection

    public let collectionId: ModelCollectionId = { return "empty-\(UUID().uuidString)" }()

    public let state = ModelCollectionState.loaded([])

    // MARK: CollectionEventObservable

    public func addObserver(_ observer: @escaping CollectionEventObserver) -> CollectionEventObserverToken {
        return Token.dummy
    }

    public func removeObserver(with token: CollectionEventObserverToken) {}
}
