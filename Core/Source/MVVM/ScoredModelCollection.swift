import Foundation

/// Scoring closure - returns a score for each model.  If no score, model is filtered out of collection. Otherwise the collection is sorted with higher scores at the top.
public typealias ModelScorer = (Model) -> Double?

/// `ModelCollection` which filters and sorts a given ModelCollection by the provided scorer function.
public final class ScoredModelCollection: ModelCollection, ProxyingCollectionEventObservable {

    // MARK: Init

    public init(_ sourceCollection: ModelCollection) {
        self.sourceCollection = sourceCollection
        self.scorer = { _ in 0 }

        sourceObserver = self.sourceCollection.observe { [weak self] event in
            self?.handleSourceEvent(event)
        }

        updateSections()
    }

    // MARK: Public

    public var sectionLimit: Int? = nil {
        didSet {
            if sectionLimit != oldValue {
                updateSections()
            }
        }
    }

    public var scorer: ModelScorer {
        didSet {
            updateSections()
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

    public var proxiedObservable: GenericObservable<CollectionEvent> { return observers }
    private let observers = ObserverList<CollectionEvent>()

    // MARK: Private

    private let sourceCollection: ModelCollection
    private var sourceObserver: Observer?

    private func handleSourceEvent(_ event: CollectionEvent) {
        updateSections()
    }

    private func updateSections() {
        var scoredSections: [Model] = []
        for section in sourceCollection.sections {
            
            var scores: [(Int, Double)] = []
            scores.reserveCapacity(section.count)
            for (index, model) in section.enumerated() {
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
            if let sectionLimit = sectionLimit, scores.count > sectionLimit {
                scores = Array(scores.prefix(sectionLimit))
            }

            scoredSections.append(scores.map { section[$0.0] })
        }
        switch sourceCollection.state {
        case .error, .notLoaded:
            state = sourceCollection.state
        case .loading:
            state = .loading(scoredSections)
        case .loaded:
            state = .loaded(scoredSections)
        }
    }
}
