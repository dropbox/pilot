import Foundation

internal final class StaticSectionedModelCollection: ModelCollection, SectionedModelCollection {
    internal init(_ modelCollection: ModelCollection) {
        self.represented = modelCollection
    }

    // MARK: ModelCollection

    internal func addObserver(_ observer: @escaping  CollectionEventObserver) -> CollectionEventObserverToken {
        return represented.addObserver(observer)
    }

    internal func removeObserver(with token: CollectionEventObserverToken) {
        represented.removeObserver(with: token)
    }

    internal var collectionId: ModelCollectionId { return represented.collectionId }
    internal var state: ModelCollectionState { return represented.state }

    // MARK: Private

    private let represented: ModelCollection
}
