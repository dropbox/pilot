import Foundation
import RxSwift

/// Simple class that provides ModelCollection conformance to a series of events, easiest way to quickly wrap something
/// that will emit models into a ModelCollection.
open class SimpleModelCollection: ObservableType {

    public init() {}

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
        case .loading(let models): subject.onNext(.loading(models))
        case .error(let e): subject.onNext(.error(e))
        case .loaded(let models): subject.onNext(.loaded(models))
        }
    }

    // MARK: ObservableType

    public typealias E = ModelCollectionState
    public func subscribe<O>(_ observer: O) -> Disposable where O : ObserverType, O.E == ModelCollectionState {
        return subject.subscribe(observer)
    }

    // MARK: Private

    private let subject = BehaviorSubject<ModelCollectionState>(value: .notLoaded)
}

/// Simple class that provides SectionedModelCollection conformance to a series of events, easiest way to quickly wrap
/// something that will emit models into a SectionedModelCollection.
open class SimpleSectionedModelCollection: ObservableType {

    public init() {}

    /// Event type the SimpleModelCollection consumes
    ///
    /// SimpleModelCollection will begin as a notLoaded ModelCollection, the other event cases match 1:1 with
    /// state values.
    public enum Event {
        case loading([[Model]]?)
        case error(Error)
        case loaded([[Model]])
    }

    /// Public called to notify the model collection of an event.
    public final func onNext(_ event: Event) {
        switch event {
        case .loading(let models): subject.onNext(models?.map({ .loading($0) }) ?? [.loading(nil)])
        case .error(let e): subject.onNext([.error(e)])
        case .loaded(let models): subject.onNext(models.map({ .loaded($0) }))
        }
    }

    // MARK: ObservableType

    public typealias E = [ModelCollectionState]
    public func subscribe<O>(_ observer: O) -> Disposable where O : ObserverType, O.E == [ModelCollectionState] {
        return subject.subscribe(observer)
    }

    // MARK: Private

    private let subject = BehaviorSubject<[ModelCollectionState]>(value: [.notLoaded])
}

