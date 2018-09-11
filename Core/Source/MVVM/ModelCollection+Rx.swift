#if canImport(RxSwift)
import RxSwift

extension ModelCollection {

    /// Returns an observable of `state` starting with the current value.
    public func stateObservable() -> Observable<ModelCollectionState> {
        return Observable
            .create { (observer) in
                let sub = self.observeValues {
                    switch $0 {
                    case .didChangeState(let state): observer.onNext(state)
                    }
                }
                return Disposables.create {
                    sub.unsubscribe()
                }
            }
            .startWith(state)
    }

    /// Returns an observable of `state.models` starting with the current value of `models`.
    public func modelsObservable() -> Observable<[Model]> {
        return Observable
            .create { (observer) in
                let sub = self.observeValues {
                    switch $0 {
                    case .didChangeState(let state): observer.onNext(state.models)
                    }
                }
                return Disposables.create {
                    sub.unsubscribe()
                }
            }
            .startWith(models)
    }
}

extension RxSwift.Observable {
    
    /// Create a ModelCollection from any Observable by providing a function to convert (E) -> ModelCollectionState.
    ///
    /// .error events are represented as ModelCollectionState.error
    /// .completed events are dropped
    public func mappedModelCollection(_ map: @escaping (E) -> ModelCollectionState) -> ModelCollection {
        let modelCollection = RxModelCollectionSink()
        
        let subscription = subscribe { [weak modelCollection] (event) in
            guard let strongModelCollection = modelCollection else { return }
            switch event {
            case .next(let e): strongModelCollection.state = map(e)
            case .error(let e): strongModelCollection.state = .error(e)
            case .completed: break
            }
        }
        
        subscription.disposed(by: modelCollection.bag)
        
        return modelCollection
    }
    
    /// Create a ModelCollection from any Observable by providing a function to convert (E) -> [ModelCollectionState].
    ///
    /// .error events are represented as ModelCollectionState.error
    /// .completed events are dropped
    public func mappedSectionedModelCollection(_ map: @escaping (E) -> [ModelCollectionState]) -> ModelCollection {
        let modelCollection = RxSectionedModelCollectionSink()
        
        let subscription = subscribe { [weak modelCollection] (event) in
            guard let strongModelCollection = modelCollection else { return }
            switch event {
            case .next(let e): strongModelCollection.sectionedState = map(e)
            case .error(let e): strongModelCollection.sectionedState = [.error(e)]
            case .completed: break
            }
        }
        
        subscription.disposed(by: modelCollection.bag)

        return modelCollection
    }
}

/// Allows implementation of ModelCollection's bridging from RxSwift by just mutating `state`.
private class RxModelCollectionSink: ModelCollection, ProxyingCollectionEventObservable {
    fileprivate init() {}
    
    fileprivate var state: ModelCollectionState = .notLoaded {
        didSet {
            assert(Thread.isMainThread, "state should only be set on main thread")
            observers.notify(.didChangeState(state))
        }
    }
    
    let collectionId: ModelCollectionId = Token.makeUnique().stringValue
    func reloadWithCompletionHandler(_ completionHandler: @escaping () -> Void) { completionHandler() }
    
    fileprivate var bag = RxSwift.DisposeBag()
    
    // MARK: CollectionEventObservable
    
    fileprivate var proxiedObservable: Observable<CollectionEvent> { return observers }
    private let observers = ObserverList<CollectionEvent>()
}

/// Allows implementation of SectionedModelCollection bridging from RxSwift by just mutating `sectionedState`.
private class RxSectionedModelCollectionSink: SectionedModelCollection, ProxyingCollectionEventObservable {
    fileprivate init() {}
    
    fileprivate var sectionedState: [ModelCollectionState] = [] {
        didSet {
            assert(Thread.isMainThread, "sectionedState should only be set on main thread")
            observers.notify(.didChangeState(state))
        }
    }
    
    fileprivate var state: ModelCollectionState {
        return sectionedState.flattenedState()
    }
    
    let collectionId: ModelCollectionId = Token.makeUnique().stringValue
    func reloadWithCompletionHandler(_ completionHandler: @escaping () -> Void) { completionHandler() }
    
    fileprivate var bag = RxSwift.DisposeBag()
    
    // MARK: CollectionEventObservable
    
    fileprivate var proxiedObservable: Observable<CollectionEvent> { return observers }
    private let observers = ObserverList<CollectionEvent>()
}

#endif
