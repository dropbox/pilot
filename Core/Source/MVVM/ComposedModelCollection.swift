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
        return ComposedModelCollection(modelCollections: modelCollections, reducer: { substates in
            var consolidatedSections: [Model] = []
            for substate in substates {
                substate.models.forEach {
                    consolidatedSections.append($0)
                }
            }

            // swiftlint:disable nesting
            struct CollectionStateReduction {
                var notLoadedCount = 0
                var loadingCount = 0
                var loadedCount = 0
                var loadingMoreCount = 0
                var errorArray: [Error] = []
            }
            // swiftlint:enable nesting

            var reducedStates = CollectionStateReduction()
            for substate in substates {
                switch substate {
                case .notLoaded:
                    reducedStates.notLoadedCount += 1
                case .loaded:
                    reducedStates.loadedCount += 1
                case .error(let error):
                    reducedStates.errorArray.append(error)
                case .loading(let models):
                    if models == nil {
                        reducedStates.loadingCount += 1
                    } else {
                        reducedStates.loadingMoreCount += 1
                    }
                }
            }

            if !reducedStates.errorArray.isEmpty {
                let error = MultiplexedError(errors: reducedStates.errorArray)
                return .error(error)
            } else if reducedStates.notLoadedCount == substates.count {
                return .notLoaded
            } else if reducedStates.loadedCount == substates.count {
                return .loaded(consolidatedSections)
            } else if reducedStates.loadingCount + reducedStates.notLoadedCount == substates.count {
                return .loading(nil)
            } else {
                return .loading(consolidatedSections)
            }
        })
    }

    public struct MultiplexedError: Error {
        public var errors: [Error]
    }
}
