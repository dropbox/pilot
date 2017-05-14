/// Simple class that provides ModelCollection conformance to a series of events, easiest way to quickly wrap something
/// that will emit models into a ModelCollection.
open class SimpleModelCollection: ModelCollection, ProxyingCollectionEventObservable {

    public init(collectionId: ModelCollectionId = "simplemodelcollection-" + Token.makeUnique().stringValue) {
        self.collectionId = collectionId
    }

    /// Event type the SimpleModelCollection consumes
    ///
    /// SimpleModelCollection will begin as a notLoaded ModelCollection, the other event cases match 1:1 with
    /// state values.
    public enum Event {
        case loading([Model]?)
        case error(Error)
        case loaded([Model])
    }

    /// Public called to notify the model collection of an event.
    public final func onNext(_ event: Event) {
        switch event {
        case .loading(let models): state = .loading(models)
        case .error(let e): state = .error(e)
        case .loaded(let models): state = .loaded(models)
        }
    }

    // MARK: ModelCollection

    public let collectionId: ModelCollectionId

    public private(set) final var state = ModelCollectionState.notLoaded {
        didSet {
            precondition(Thread.isMainThread)
            observers.notify(.didChangeState(state))
        }
    }

    // MARK: CollectionEventObservable

    public final var proxiedObservable: GenericObservable<CollectionEvent> { return observers }
    private final let observers = ObserverList<CollectionEvent>()
}
