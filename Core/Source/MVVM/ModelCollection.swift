import Foundation

/// Possible states for a `ModelCollection`. These states are typically used only for reference-type implementations
/// of `ModelCollection` since value-type implementations will typically always be `Loaded`.
public enum ModelCollectionState {
    /// The model collection is instantiated but has not yet attempted to load data.
    case notLoaded

    /// The model collection is loading content, models will be nil if loading for the first time.
    case loading([Model]?)

    /// The model collection has successfully loaded data.
    case loaded([Model])

    /// The model collection encountered an error loading data.
    case error(Error)

    /// Unpacks and returns any associated model models.
    public var models: [Model] {
        switch self {
        case .notLoaded, .error:
            return []
        case .loading(let models):
            return models ?? []
        case .loaded(let models):
            return models
        }
    }

    /// Returns whether or not the underlying enum case is different than the target. Ignores associated model
    /// objects.
    public func isDifferentCase(than other: ModelCollectionState) -> Bool {
        switch (self, other) {
        case (.notLoaded, .notLoaded),
             (.loading(_), .loading(_)),
             (.loaded(_), .loaded(_)),
             (.error(_), .error(_)):
            return false
        default:
            return true
        }
    }
}

/// Event types sent to `CollectionEventObserver` types.
public enum CollectionEvent {

    /// Issued right after the `state` variable changes.
    case didChangeState(ModelCollectionState)
}

// MARK: Observing

/// There are many similarities between this code and the code around Observable.  The
/// primary distinction is that Observable has an associated Event type, where CollectionEventObservable
/// is hard-coded to observe CollectionEvents.  Because Observable has an associated type,
/// it cannot be used as a type, only as a generic constraint.  If this restriction is lifted in a future
/// version of Swift, CollectionEventObservable can be replaced with Observable.

/// Observer defined as a closure. Type-erasing in this closure allows the actual observer to be a value type or
/// reference type with a captured weak self.
public typealias CollectionEventObserver = (CollectionEvent) -> Void
public typealias CollectionEventObserverToken = Token

/// ProxyingCollectionEventObservable is the easiest way to implement the CollectionEventObservable protocol.
/// See the documentation for `ProxyingObservable` - it has the same API.
///
/// The relevant boilerplate to implement ProxyingCollectionEventObservable is as follows:
///
/// ```swift
/// public var proxiedObservable: GenericObservable<CollectionEvent> { return observers }
/// private let observers = ObserverList<CollectionEvent>()
/// ```
public protocol ProxyingCollectionEventObservable {
    var proxiedObservable: GenericObservable<CollectionEvent> { get }
}

/// The default CollectionEventObservable implementations.
extension ProxyingCollectionEventObservable {
    public func addObserver(_ observer: @escaping (CollectionEvent) -> Void) -> ObserverToken {
        return proxiedObservable.addObserver(observer)
    }
    public func removeObserver(with token: ObserverToken) {
        return proxiedObservable.removeObserver(with: token)
    }
}

/// IndexPath is too expensive (given it contains an NSArray) for what really is just two indices, so we pass these simple ModelPath pairs
/// around.  `sectionIndex` is the index of the section and `itemIndex` is the index of the model in the corresponding section.
public struct ModelPath: Equatable, Hashable {
    public init(sectionIndex: Int, itemIndex: Int) {
        self.sectionIndex = sectionIndex
        self.itemIndex = itemIndex
    }

    public init(_ sectionIndex: Int, _ itemIndex: Int) {
        self.init(sectionIndex: sectionIndex, itemIndex: itemIndex)
    }

    public var sectionIndex: Int
    public var itemIndex: Int

    // MARK: Hashable

    public var hashValue: Int {
        return sectionIndex.hashValue ^ itemIndex.hashValue
    }
}

public func ==(lhs: ModelPath, rhs: ModelPath) -> Bool {
    return lhs.sectionIndex == rhs.sectionIndex && lhs.itemIndex == rhs.itemIndex
}

public func <(lhs: ModelPath, rhs: ModelPath) -> Bool {
    if lhs.sectionIndex < rhs.sectionIndex {
        return true
    } else if lhs.sectionIndex > rhs.sectionIndex {
        return false
    } else {
        return lhs.itemIndex < rhs.itemIndex
    }
}

public extension ModelPath {
    public var indexPath: IndexPath {
        return IndexPath(indexes: [sectionIndex, itemIndex])
    }
}

public extension IndexPath {
    public var modelPath: ModelPath {
        return ModelPath(sectionIndex: self[0], itemIndex: self[1])
    }
}

/// Named tuples don't automatically implement Equatable so do it manually.
public struct MovedModel: Equatable {
    public var from: ModelPath
    public var to: ModelPath

    public init(from: ModelPath, to: ModelPath) {
        self.from = from
        self.to = to
    }
}

public func ==(lhs: MovedModel, rhs: MovedModel) -> Bool {
    return lhs.from == rhs.from && lhs.to == rhs.to
}

public typealias ModelCollectionId = String

// MARK: IndexedModelProvider

/// Core provider protocol to generate `Model` instances from index paths.
public protocol IndexedModelProvider {
    /// Returns a `Model` for the given `IndexPath` and context.
    func model(for indexPath: IndexPath, context: Context) -> Model?
}

// MARK: ModelCollection

/// Generic protocol defining a collection of `Model` items grouped into models. This is the core Pilot
/// collection protocol for representing a collection of model items. View-specific bindings are provided by the
/// PilotUI framework.
public protocol ModelCollection: class {

    // MARK: Observable

    func addObserver(_ observer: @escaping  CollectionEventObserver) -> CollectionEventObserverToken
    func removeObserver(with token: CollectionEventObserverToken)

    var collectionId: ModelCollectionId { get }

    // MARK: State

    /// Current state of the model collection. Typically used by reference-type implementations, as value-type
    /// implementations stay `.Loaded`.
    var state: ModelCollectionState { get }
}

public extension ModelCollection {
    public func observe(_ handler: @escaping (CollectionEvent) -> Void) -> Observer {
        let token = addObserver(handler)
        return Observer { [weak self] in
            self?.removeObserver(with: token)
        }
    }
}

// MARK: Common helper methods.

/// Returns a dictionary mapping `ModelId`s to their index path within the given `models` object.
public func generateModelIdToIndexPathMapForSections(_ models: [Model]) -> [ModelId: ModelPath] {
    var map: [ModelId: ModelPath] = [:]
    for (idx, model) in models.enumerated() {
        map[model.modelId] = ModelPath(sectionIndex: 0, itemIndex: idx)
    }
    return map
}

extension ModelCollectionState {
    public var isNotLoaded: Bool {
        if case .notLoaded = self { return true }
        return false
    }

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }

    public var isEmpty: Bool {
        switch self {
        case .notLoaded, .error:
            return true
        case .loading(let models):
            guard let models = models else { return true }
            return models.isEmpty
        case .loaded(let models):
            return models.isEmpty
        }
    }
}

extension ModelCollectionState: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .notLoaded:
            return ".notLoaded"
        case .error(let e):
            return ".error(\(String(reflecting: e)))"
        case .loading(let models):
            return ".loading(\(describe(models: models)))"
        case .loaded(let models):
            return ".loaded(\(describe(models: models)))"
        }
    }

    private func describe(models: [Model]?) -> String {
        guard let models = models else { return "nil" }
        return "[\(models.count) Models]"
    }
}

extension ModelCollection {

    public var models: [Model] { return state.models }
    public var sections: [[Model]] { return [models] }

    /// Returns a dictionary mapping item `ModelId`s to their index path within the target `ModelCollection`.
    public var modelIdToIndexPathMap: [ModelId: ModelPath] {
        return generateModelIdToIndexPathMapForSections(models)
    }

    /// Convenience methods to return the total number of items in a `ModelCollection`.
    /// TODO:(danielh) deprecate?
    public var totalItemCount: Int {
        return models.count
    }

    /// Returns `true` if the collection is completely empty, `false` otherwise.
    public var isEmpty: Bool {
        return models.isEmpty
    }

    /// Returns a typed cast of the model value at the given index path, or nil if the model is not of that type or
    /// the index path is out of bounds.
    public func atIndexPath<T>(_ indexPath: IndexPath) -> T? {
        guard indexPath.modelSection == 0 else { return nil } // TODO:(danielh) throw/log error?
        if models.indices.contains(indexPath.modelItem) {
            return models[indexPath.modelItem] as? T
        }
        return nil
    }

    /// Returns a typed cast of the model value at the given index path, or nil if the model is not of that type or
    /// the index path is out of bounds.
    public func atModelPath<T>(_ modelPath: ModelPath) -> T? {
        guard modelPath.sectionIndex == 0 else { return nil } // TODO:(danielh) throw/log error?
        if case models.indices = modelPath.itemIndex {
            return models[modelPath.itemIndex] as? T
        }
        return nil
    }

    /// Returns the index path for the given model id, if present.
    /// - Complexity: O(n)
    public func indexPath(forModelId modelId: ModelId) -> IndexPath? {
        return indexPathOf() { $0.modelId == modelId }
    }

    /// Returns the index path for first item matching the provided closure
    /// - Complexity: O(n)
    public func indexPathOf(matching: (Model) -> Bool) -> IndexPath? {
        if let idx = models.index(where: matching) {
            return IndexPath(forModelItem: idx, inSection: 0)
        }
        return nil
    }
}

// Pilot does not depend on UIKit, so redefine similar section/item accessors and initializers here.
public extension IndexPath {
    public var modelSection: Int {
        return self[0]
    }
    public var modelItem: Int {
        return self[1]
    }
    public init(forModelItem modelItem: Int, inSection modelSection: Int) {
        self.init(indexes: [modelSection, modelItem])
    }
}
