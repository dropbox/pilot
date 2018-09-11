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
    public enum SimpleEvent {
        case loading([Model]?)
        case error(Error)
        case loaded([Model])
    }

    /// Public called to notify the model collection of an event.
    public final func onNext(_ event: SimpleEvent) {
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

    public final var proxiedObservable: Observable<CollectionEvent> { return observers }
    private final let observers = ObserverList<CollectionEvent>()
}

/// Simple class that provides SectionedModelCollection conformance to a series of events, easiest way to quickly wrap
/// something that will emit models into a SectionedModelCollection.
open class SimpleSectionedModelCollection: SectionedModelCollection, ProxyingCollectionEventObservable {

    public init(collectionId: ModelCollectionId = "simplemodelcollection-" + Token.makeUnique().stringValue) {
        self.collectionId = collectionId
    }

    /// Event type the SimpleSectionedModelCollection consumes
    ///
    /// SimpleSectionedModelCollection will begin as a notLoaded SectionedModelCollection, the other event cases match
    /// 1:1 with state values.
    public enum SimpleSectionedEvent {
        case loading([[Model]]?)
        case error(Error)
        case loaded([[Model]])
    }

    /// Public called to notify the model collection of an event.
    public final func onNext(_ event: SimpleSectionedEvent) {
        switch event {
        case .loading(let sections):
            if let sections = sections {
                sectionedState = sections.map { .loading($0) }
            } else {
                sectionedState = [.loading(nil)]
            }
        case .error(let e):
            sectionedState = [.error(e)]
        case .loaded(let sections):
            sectionedState = sections.map { .loaded($0) }
        }
    }

    // MARK: ModelCollection

    public let collectionId: ModelCollectionId

    public final var state: ModelCollectionState {
        return sectionedState.flattenedState()
    }

    // MARK: SectionedModelCollection

    public private(set) final var sectionedState: [ModelCollectionState] = [] {
        didSet {
            precondition(Thread.isMainThread)
            observers.notify(.didChangeState(state))
        }
    }

    // MARK: CollectionEventObservable

    public final var proxiedObservable: Observable<CollectionEvent> { return observers }
    private final let observers = ObserverList<CollectionEvent>()
}
