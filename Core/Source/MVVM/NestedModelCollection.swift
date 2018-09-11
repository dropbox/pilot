import Foundation

/// Specialization of a `ModelCollection` that provides support for nesting - that is having multiple levels of models
/// for example when displaying in an outline or browser view.
public protocol NestedModelCollection: ModelCollection {
    func canExpand(_ model: Model) -> Bool
    func childModelCollection(for: Model) -> NestedModelCollection
}

public extension ModelCollection {
    public func asNested() -> NestedModelCollection {
        if let nested = self as? NestedModelCollection { return nested }
        return SingleLevelNestedModelCollection(self)
    }
}

/// Private only class used for wrapping non-nested `ModelCollection` into a nested model collection.
private final class SingleLevelNestedModelCollection: NestedModelCollection {

    internal init(_ modelCollection: ModelCollection) {
        self.represented = modelCollection
    }

    // MARK: NestedModelCollection

    func canExpand(_ model: Model) -> Bool {
        return false
    }

    func childModelCollection(for model: Model) -> NestedModelCollection {
        return EmptyModelCollection().asNested()
    }

    // MARK: ModelCollection

    func observeValues(_ observer: @escaping (CollectionEvent) -> Void) -> Subscription {
        return represented.observeValues(observer)
    }

    var collectionId: ModelCollectionId { return represented.collectionId }
    var state: ModelCollectionState { return represented.state }

    // MARK: Private

    private let represented: ModelCollection
}
