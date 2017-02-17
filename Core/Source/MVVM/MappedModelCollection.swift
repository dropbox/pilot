import Foundation

/// Transform closure that is performed on each model item.
public typealias ModelTransform = (Model) -> Model

/// `ModelCollectionType` which provides basic map support on top of an existing source `ModelCollectionType`.
public final class MappedModelCollection: ModelCollection, ProxyingCollectionEventObservable {

    // MARK: Init

    public init(sourceCollection: ModelCollection) {
        self.sourceCollection = sourceCollection

        sourceObserver = self.sourceCollection.observe { [weak self] event in
            self?.handleSourceEvent(event)
        }

        state = self.sourceCollection.state
    }

    // MARK: Public

    public var transform: ModelTransform = { model in return model } {
        willSet {
            discardPendingMapWork()
        }
        didSet {
            // Don't need to run the mapping function yet if still loading (otherwise observers will think this has
            // loaded when the spinner completes). It will get run when data comes in.
            guard !state.isLoading else { return }

            runTransform()
        }
    }

    // MARK: ModelCollection

    public var collectionId: ModelCollectionId {
        return "mapped-\(sourceCollection.collectionId)"
    }

    public internal(set) var state = ModelCollectionState.notLoaded {
        didSet {
            observers.notify(.didChangeState(state))
        }
    }

    // MARK: CollectionEventObservable

    public var proxiedObservable: GenericObservable<CollectionEvent> { return observers }
    private let observers = ObserverList<CollectionEvent>()

    // MARK: Private

    private let sourceCollection: ModelCollection
    private var sourceObserver: Observer?

    internal func handleSourceEvent(_ event: CollectionEvent) {
        discardPendingMapWork()
        runTransform()
    }

    private var mapCookie = 0

    private func discardPendingMapWork() {
        assert(Thread.isMainThread)
        mapCookie = mapCookie + 1
    }

    private func runTransform() {
        assert(Thread.isMainThread)

        let originalSections = sourceCollection.sections
        let originalTranform = transform
        let originalCookie = mapCookie

        state = .loading(state.sections)

        var newSections: [[Model]] = []

        Async.onUserInitiated {
            newSections = originalSections.map { $0.map(originalTranform) }
        }.onMain { [weak self] in
            guard let strongSelf = self else { return }

            // Drop work if the cookie is outdated.
            guard originalCookie == strongSelf.mapCookie else { return }
            strongSelf.state = .loaded(newSections)
        }
    }
}
