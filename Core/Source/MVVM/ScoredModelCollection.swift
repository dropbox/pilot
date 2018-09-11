import Foundation
#if canImport(RxSwift)
import RxSwift
#endif

/// Scoring closure - returns a score for each model.  If no score, model is filtered out of collection. Otherwise the collection is sorted with higher scores at the top.
public typealias ModelScorer = (Model) -> Double?

/// `ModelCollection` which filters and sorts a given ModelCollection by the provided scorer function.
public final class ScoredModelCollection: ModelCollection, ProxyingCollectionEventObservable {

    // MARK: Init

    public init(_ sourceCollection: ModelCollection) {
        self.sourceCollection = sourceCollection
        self.scorer = { _ in 0 }

        sourceObserver = self.sourceCollection.observeValues { [weak self] event in
            self?.handleSourceEvent(event)
        }

        updateModels()
    }

    // MARK: Public

    public var limit: Int? = nil {
        didSet {
            if limit != oldValue {
                updateModels()
            }
        }
    }

    public var scorer: ModelScorer {
        didSet {
            updateModels()
        }
    }

    // MARK: ModelCollection

    public var collectionId: ModelId {
        return "scored-\(sourceCollection.collectionId)"
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

    private func handleSourceEvent(_ event: CollectionEvent) {
        updateModels()
    }

    private func updateModels() {
        var scores: [(Int, Double)] = []
        scores.reserveCapacity(sourceCollection.models.count)
        for (index, model) in sourceCollection.models.enumerated() {
            if let score = scorer(model) {
                scores.append((index, score))
            }
        }
        scores.sort(by: {
            if ($0.1 < $1.1) {
                return false
            } else if ($0.1 > $1.1) {
                return true
            } else {
                return $0.0 < $1.0
            }
        })
        if let limit = limit, scores.count > limit {
            scores = Array(scores.prefix(limit))
        }
        let results = scores.map { sourceCollection.models[$0.0] }
        switch sourceCollection.state {
        case .error, .notLoaded:
            state = sourceCollection.state
        case .loading:
            state = .loading(results)
        case .loaded:
            state = .loaded(results)
        }
    }
}
