import Foundation

public final class ComposedModelCollection: ModelCollection, ProxyingCollectionEventObservable {

    public init(
        collectionId: ModelCollectionId = "ComposedModelCollection-" + Token.makeUnique().stringValue,
        modelCollections: [ModelCollection],
        reducer: @escaping ([ModelCollectionState]) -> ModelCollectionState
    ) {
        self.collectionId = collectionId
        self.modelCollections = modelCollections
        self.reducer = reducer
        self.composedCollectionObservers = modelCollections.map { (modelCollection) -> Observer in
            return modelCollection.observe { [weak self] _ in
                self?.updateState()
            }
        }
        updateState()
    }

    public let modelCollections: [ModelCollection]
    public let reducer: ([ModelCollectionState]) -> ModelCollectionState

    // MARK: ModelCollection

    public let collectionId: ModelCollectionId
    public private(set) var state: ModelCollectionState = .notLoaded {
        didSet {
            precondition(Thread.isMainThread)
            observers.notify(.didChangeState(state))
        }
    }

    // MARK: Private

    private var composedCollectionObservers = [Observer]()
    private func updateState() {
        self.state = reducer(modelCollections.map({ $0.state }))
    }

    // MARK: CollectionEventObservable

    public final var proxiedObservable: GenericObservable<CollectionEvent> { return observers }
    private final let observers = ObserverList<CollectionEvent>()
}

extension ComposedModelCollection {
    public static func multiplexing(_ modelCollections: [ModelCollection]) -> ComposedModelCollection {
        return ComposedModelCollection(modelCollections: modelCollections, reducer: { $0.flattenedState() })
    }
}
