import Foundation
#if canImport(RxSwift)
import RxSwift
#endif

extension ComposedModelCollection {

    /// Returns a `ComposedModelCollection` combining all the provided model collections into a single section.
    public static func combining(_ modelCollections: [ModelCollection]) -> ComposedModelCollection {
        return ComposedModelCollection(
            modelCollections: modelCollections,
            strategy: .single,
            reducer: { $0.flattenedState() })
    }

    /// Returns a `ComposedModelCollection` combining all the provided model collections, where each model collection
    /// represents a `SectionedModelCollection` section.
    public static func multiplexing(_ modelCollections: [ModelCollection]) -> ComposedModelCollection {
        return ComposedModelCollection(
            modelCollections: modelCollections,
            strategy: .multiple,
            reducer: { $0.flattenedState() })
    }
}


/// `ModelCollection` which composes multiple other model collections. These child collections can be represented
/// as a single section, or as a section-per-model-collection, depending on the `SectionStrategy` defined at
/// initalization.
public final class ComposedModelCollection: SectionedModelCollection, ProxyingCollectionEventObservable {

    public init(
        collectionId: ModelCollectionId = "ComposedModelCollection-" + Token.makeUnique().stringValue,
        modelCollections: [ModelCollection],
        strategy: SectionStrategy,
        reducer: @escaping ([ModelCollectionState]) -> ModelCollectionState
    ) {
        self.collectionId = collectionId
        self.strategy = strategy
        self.modelCollections = modelCollections
        self.reducer = reducer
        self.composedCollectionObservers = modelCollections.map { (modelCollection) -> Subscription in
            return modelCollection.observeValues { [weak self] _ in
                self?.updateState()
            }
        }
        updateState()
    }

    public enum SectionStrategy {
        /// Internal model collections are represented externally as a single section.
        case single

        /// Internal model collections are each represented by an external section.
        case multiple
    }

    // MARK: ModelCollection

    public let collectionId: ModelCollectionId
    public private(set) var state: ModelCollectionState = .notLoaded

    // MARK: SectionedModelCollection

    public private(set) var sectionedState: [ModelCollectionState] = []

    // MARK: CollectionEventObservable

    public final var proxiedObservable: Observable<CollectionEvent> { return observers }
    private final let observers = ObserverList<CollectionEvent>()

    // MARK: Private

    private var composedCollectionObservers = [Subscription]()
    private func updateState() {
        precondition(Thread.isMainThread)

        switch strategy {
        case .single:
            state = reducer(modelCollections.map({ $0.state }))
            sectionedState = [state]
        case .multiple:
            sectionedState = modelCollections.map({ $0.state })
            state = reducer(sectionedState)
        }
        observers.notify(.didChangeState(state))
    }

    // MARK: Private

    private let strategy: SectionStrategy
    private let modelCollections: [ModelCollection]
    private let reducer: ([ModelCollectionState]) -> ModelCollectionState
}


