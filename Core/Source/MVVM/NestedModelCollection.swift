import Foundation

/// Specialization of a `ModelCollection` that provides support for nesting - that is having multiple levels of models
/// for example when displaying in an outline or browser view.
public protocol NestedModelCollection: ModelCollection {
    func isModelExpandable(_ model: Model) -> Bool
    func childModelCollection(_ model: Model) -> NestedModelCollection
}

public extension ModelCollection {
    public func asNested() -> NestedModelCollection {
        if let nested = self as? NestedModelCollection { return nested }
        return SingleLevelNestedModelCollection(self)
    }
}

/// Internal only class used for wrapping non-nested `ModelCollection` into a nested model collection.
internal final class SingleLevelNestedModelCollection: NestedModelCollection {

    internal init(_ modelCollection: ModelCollection) {
        self.represented = modelCollection
    }

    // MARK: NestedModelCollection

    func isModelExpandable(_ model: Model) -> Bool {
        return false
    }

    func childModelCollection(_ model: Model) -> NestedModelCollection {
        return EmptyModelCollection().asNested()
    }

    // MARK: ModelCollection

    func addObserver(_ observer: @escaping CollectionEventObserver) -> CollectionEventObserverToken {
        return represented.addObserver(observer)
    }

    func removeObserver(with token: CollectionEventObserverToken) {
        represented.removeObserver(with: token)
    }

    var collectionId: ModelCollectionId { return represented.collectionId }
    var state: ModelCollectionState { return represented.state }

    // MARK: Private

    private let represented: ModelCollection
}
