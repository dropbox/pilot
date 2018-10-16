import Foundation
import RxSwift

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

/// An `IndexedModelProvider` implementation that delegates to a closure to provide the
/// appropriate model for the supplied `IndexPath` and `Context`.
public struct BlockModelProvider: IndexedModelProvider {
    public init(binder: @escaping (IndexPath, Context) -> Model?) {
        self.binder = binder
    }

    public func model(for indexPath: IndexPath, context: Context) -> Model? {
        return binder(indexPath, context)
    }

    private let binder: (IndexPath, Context) -> Model?
}

// MARK: ModelCollection

public typealias SectionedModelCollection = Observable<[ModelCollectionState]>
public typealias ModelCollection = Observable<ModelCollectionState>

// MARK: Common helper methods.

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
