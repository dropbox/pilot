import Foundation

/// StaticModelCollection is a ModelCollection that never changes and whose data is known and specified upon
/// construction.
/// TODO:(wkiefer) Expand these docs and show how this can be composed with `FilteredModelCollection` and
/// `MultiplexModelCollection`.
public final class StaticModelCollection: ModelCollection {

    // MARK: Init

    public init(collectionId: ModelCollectionId, initialData: [Model]) {
        self.collectionId = collectionId
        self.state = .loaded(initialData)
    }

    public convenience init(_ initialData: [Model]) {
        self.init(collectionId: "StaticModelCollection-\(UUID().uuidString)", initialData: initialData)
    }

    // MARK: ModelCollection

    public let collectionId: ModelCollectionId
    public let state: ModelCollectionState

    // MARK: CollectionEventObservable

    public func addObserver(_ observer: @escaping CollectionEventObserver) -> CollectionEventObserverToken {
        return Token.dummy
    }

    public func removeObserver(with token: CollectionEventObserverToken) {
    }
}
