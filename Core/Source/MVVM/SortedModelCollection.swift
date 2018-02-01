import Foundation

/// Compares two models and returns a `Bool` indicating if the first model should be ordered first.
public typealias ModelComparator = (Model, Model) -> Bool

/// `ModelCollection` which sorts models within sections of the given ModelCollection,
/// by the provided comparator function.
public final class SortedModelCollection: ModelCollection, ProxyingCollectionEventObservable {

    // MARK: Init

    public init(_ sourceCollection: ModelCollection) {
        self.sourceCollection = sourceCollection
        self.comparator = { _, _ in false }

        sourceObserver = self.sourceCollection.observe { [weak self] event in
            self?.updateSections()
        }
        updateSections()
    }

    // MARK: Public

    public var comparator: ModelComparator {
        didSet {
            updateSections()
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

    public var proxiedObservable: GenericObservable<CollectionEvent> { return observers }
    private let observers = ObserverList<CollectionEvent>()

    // MARK: Private

    private let sourceCollection: ModelCollection
    private var sourceObserver: Observer?

    private func updateSections() {
        var sortedSections: [[Model]] = []
        for section in sourceCollection.sections {
            sortedSections.append(section.sorted(by: comparator))
        }

        switch sourceCollection.state {
        case .error, .notLoaded:
            state = sourceCollection.state
        case .loading:
            state = .loading(sortedSections)
        case .loaded:
            state = .loaded(sortedSections)
        }
    }
}
