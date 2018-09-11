import Foundation
#if canImport(RxSwift)
import RxSwift
#endif

/// Compares two models and returns a `Bool` indicating if the first model should be ordered first.
public typealias ModelComparator = (Model, Model) -> Bool

/// `ModelCollection` which sorts models within sections of the given ModelCollection,
/// by the provided comparator function.
public final class SortedModelCollection: ModelCollection, ProxyingCollectionEventObservable {

    // MARK: Init

    public init(_ sourceCollection: ModelCollection) {
        self.sourceCollection = sourceCollection
        self.comparator = { _, _ in false }
        sourceObserver = self.sourceCollection.observeValues { [weak self] event in
            self?.sortModels()
        }
        sortModels()
    }

    // MARK: Public

    public var comparator: ModelComparator {
        didSet {
            sortModels()
        }
    }

    // MARK: ModelCollection

    public var collectionId: ModelId {
        return "sorted-\(sourceCollection.collectionId)"
    }

    public private(set) var state: ModelCollectionState = .notLoaded {
        didSet {
            observers.notify(.didChangeState(state))
        }
    }

    // MARK: CollectionEventObservable

    public var proxiedObservable: Observable<CollectionEvent> { return observers }
    private let observers = ObserverList<CollectionEvent>()

    // MARK: Private

    private let sourceCollection: ModelCollection
    private var sourceObserver: Subscription?

    private func sortModels() {
        let sorted = sourceCollection.models.sorted(by: comparator)
        switch sourceCollection.state {
        case .error, .notLoaded:
            state = sourceCollection.state
        case .loading:
            state = .loading(sorted)
        case .loaded:
            state = .loaded(sorted)
        }
    }
}
