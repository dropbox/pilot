import Foundation

/// StaticModelCollection is a ModelCollection that never changes and whose data is known and specified upon
/// construction.
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

    public func observeValues(_ observer: @escaping (CollectionEvent) -> Void) -> Subscription {
        return Subscription.inert
    }
}

/// `StaticSectionedModelCollection` is a `StaticSectionedModelCollection` implementation for static data that
/// never changes and is known upon construction.
public final class StaticSectionedModelCollection: SectionedModelCollection {

    // MARK: Init

    public init(collectionId: ModelCollectionId, initialData: [[Model]]) {
        self.collectionId = collectionId
        self.sectionedState = initialData.map { items in
            return ModelCollectionState.loaded(items)
        }
    }

    public convenience init(_ initialData: [[Model]]) {
        self.init(collectionId: "StaticSectionedModelCollection-\(UUID().uuidString)", initialData: initialData)
    }

    // MARK: ModelCollection

    public let collectionId: ModelCollectionId

    public var state: ModelCollectionState {
        return sectionedState.flattenedState()
    }

    // MARK: SectionedModelCollection

    public let sectionedState: [ModelCollectionState]

    // MARK: CollectionEventObservable
    
    public func observeValues(_ observer: @escaping (CollectionEvent) -> Void) -> Subscription {
        return Subscription.inert
    }
}
