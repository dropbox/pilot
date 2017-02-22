import Foundation

/// A ModelCollection whose backing collection can be swapped out at runtime.
public final class SwitchableModelCollection: ModelCollection, ProxyingCollectionEventObservable {

    // MARK: Init

    public init(_ collectionId: ModelCollectionId, _ modelCollection: ModelCollection) {
        self.collectionId = collectionId
        self.currentCollection = modelCollection
        self.modelObserver = modelCollection.observe { [weak self] event in
            self?.observers.notify(event)
        }
    }

    // MARK: Public

    public func switchTo(_ modelCollection: ModelCollection) {
        self.currentCollection = modelCollection
        self.modelObserver = modelCollection.observe { [weak self] (event) in
            self?.observers.notify(event)
        }
        observers.notify(.didChangeState(state))
    }

    /// Read-only access to underlying collection, set by `switchTo(_:)`.
    public private(set) var currentCollection: ModelCollection

    // MARK: ModelCollection

    public let collectionId: ModelCollectionId

    public var state: ModelCollectionState {
        return self.currentCollection.state
    }

    // MARK: CollectionEventObservable

    public var proxiedObservable: GenericObservable<CollectionEvent> { return observers }
    private let observers = ObserverList<CollectionEvent>()

    // MARK: Private

    private var modelObserver: Observer?
}
