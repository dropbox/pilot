#if !canImport(RxSwift)

// Note: Exclude ObservableData & AnyObservableData to avoid confusion with RxSwift's comparable features with different
// terminology.

/// Represents a value whose changes can be observed.  Use the standard `Observable`
/// APIs to observe changes.
public protocol ObservableData: ObservableType {
    var data: Event { get }
}

/// Existential type wrapper around an ObservableData constraining the data type to the type parameter T.
/// Useful as a return value for functions that return some observable but the concrete observable type isn't known.
public final class AnyObservableData<T>: ObservableData {

    // MARK: Init
    
    public static func make<U: ObservableData>(_ observable: U, retained: AnyObject? = nil) -> AnyObservableData<U.Event> {
        return AnyObservableData<U.Event>.init(
            getter: { observable.data },
            subscribe: { observable.observeValues($0) },
            retained: retained)
    }

    // MARK: ObservableData

    public typealias Event = T

    public var data: T {
        return getter()
    }

    public func observeValues(_ observer: @escaping (T) -> Void) -> Subscription {
        return subscribe(observer)
    }
    
    // MARK: Private

    private init(
        getter: @escaping () -> T,
        subscribe: @escaping (@escaping (T) -> Void) -> Subscription,
        retained: AnyObject?
    ) {
        self.getter = getter
        self.subscribe = subscribe
        self.retained = retained
    }

    private let getter: () -> T
    private let subscribe: (@escaping (T) -> Void) -> Subscription
    private let retained: AnyObject?
}

/// A mutable, observable variable.  For types that implement Equatable, use `make(withEquatable:)`.
/// Otherwise, manually construct one with a specified equalityCheck.
///
/// ```swift
/// let variable = ObservableVariable.make(withEquatable: "hello")
/// observer = variable.observe { value in
///   print(value)
/// }
/// variable.data = "world"
/// ```
///
/// Note: ObservableVariable only notifies observers when `data` is updated (and if it isn't equal to the
/// previous value).  This makes ObservableVariable more useful for value types, since mutations to a
/// reference type won't trigger a change notification.  That said, it's okay to use ObservableVariable
/// with reference types.
open class ObservableVariable<T>: Observable<T>, ObservableData {
    /// Construct an ObservableVariable given a value of Equatable type.
    /// This static could go away when https://bugs.swift.org/browse/SR-2892 is fixed.
    public static func make<U: Equatable>(withEquatable initialData: U) -> ObservableVariable<U> {
        return ObservableVariable<U>(initialData: initialData, equalityCheck: (==))
    }

    // TODO(ca) Replace equalityCheck with a : Equatable constraint on T when Swift gets conditional
    // protocol conformance, specifically when Array and Option conform to Equatable
    public init(initialData: T, equalityCheck: @escaping (T, T) -> Bool) {
        self.data = initialData
        self.equalityCheck = equalityCheck
    }

    // MARK: GenericObservable
    
    open override func observeValues(_ observer: @escaping (T) -> Void) -> Subscription {
        return observers.observeValues(observer)
    }

    // MARK: ObservableData

    open var data: T {
        didSet {
            if !equalityCheck(oldValue, data) {
                observers.notify(data)
            }
        }
    }

    // MARK: Private

    private let equalityCheck: (T, T) -> Bool
    private let observers = ObserverList<T>()
}

/// An ObservableData that computes its output by observing a set of input ObservableData and running
/// a transform function across their values.
///
/// ```swift
/// let variable = ObservableVariable<Int>.make(withEquatable: 10)
/// let plusTwo = DerivedData<Int>.make(variable) { value in value + 2 }
/// let observer = plusTwo.observe { ... }
/// ```
open class DerivedData<Result>: ProxyingObservable, ObservableData {

    // NOTE: A great deal of this class, including all the custom Equatable constructors,
    // goes away when Swift gains the ability to constrain extensions.  (Slated for Swift 4.)

    // MARK: Make Equatable

    public static func make<T: ObservableData, R: Equatable>(_ root: T, transform: @escaping (T.Event) -> R) -> DerivedData<R> {
        return DerivedData<R>(root, equalityCheck: (==), transform: transform)
    }

    public static func make<A: ObservableData, B: ObservableData, R: Equatable>(_ a: A, _ b: B, transform: @escaping (A.Event, B.Event) -> R) -> DerivedData<R> {
        return DerivedData<R>(a, b, equalityCheck: (==), transform: transform)
    }

    /*
    public static func make<A: ObservableData>(a: A, equalityCheck: (Result, Result) -> Bool, transform: (A.Event) -> Result) -> DerivedData<Result> {
        return DerivedData<Result>(a, equalityCheck: equalityCheck, transform: transform)
    }

    public static func make<A: ObservableData, B: ObservableData>(a: A, _ b: B, equalityCheck: (Result, Result) -> Bool, transform: (A.Event, B.Event) -> Result) -> DerivedData<Result> {
        return DerivedData<Result>(a, b, equalityCheck: equalityCheck, transform: transform)
    }
     */

    // MARK: Init

    public init<A: ObservableData>(_ a: A, equalityCheck: @escaping (Result, Result) -> Bool, transform: @escaping (A.Event) -> Result) {
        self.data = transform(a.data)
        self.equalityCheck = equalityCheck
        self.retained = nil // need to initialize before creating a closure including self

        let observer = a.observeValues { [weak self] event in
            // TODO(ca): figure out how to convince Swift that event is always an ObservableDataEvent
            // and only recalculate on DidChange
            self?.data = transform(a.data)
        }
        retained = observer
    }

    public init<A: ObservableData, B: ObservableData>(_ a: A, _ b: B, equalityCheck: @escaping (Result, Result) -> Bool, transform: @escaping (A.Event, B.Event) -> Result) {
        self.data = transform(a.data, b.data)
        self.equalityCheck = equalityCheck
        self.retained = nil // need to initialize before creating a closure including self

        let cb: (Any) -> Void = { [weak self] event in
            self?.data = transform(a.data, b.data)
        }

        let observers = [
            a.observeValues(cb),
            b.observeValues(cb),
        ]
        retained = observers as AnyObject?
    }

    public init<A: ObservableData, B: ObservableData, C: ObservableData>(_ a: A, _ b: B, _ c: C, equalityCheck: @escaping (Result, Result) -> Bool, transform: @escaping (A.Event, B.Event, C.Event) -> Result) {
        self.data = transform(a.data, b.data, c.data)
        self.equalityCheck = equalityCheck
        self.retained = nil // need to initialize before creating a closure including self

        let cb: (Any) -> Void = { [weak self] event in
            self?.data = transform(a.data, b.data, c.data)
        }

        let observers = [
            a.observeValues(cb),
            b.observeValues(cb),
            c.observeValues(cb),
        ]
        retained = observers as AnyObject?
    }

    // TODO: Feel free to add constructors for larger numbers of source observables. :)

    // MARK: ProxyingObservable

    open var proxiedObservable: Observable<Result> { return observers }
    private let observers = ObserverList<Result>()

    // MARK: ObservableData

    public typealias Event = Result

    open private(set) var data: Result {
        didSet {
            if !equalityCheck(oldValue, data) {
                observers.notify(data)
            }
        }
    }

    // MARK: Private

    private let equalityCheck: (Result, Result) -> Bool
    private var retained: AnyObject?
}

public extension ObservableData {
    /// Same as `Observable.observeValues` except it also calls the callback immediately with the initial value.
    /// Useful when binding some UI to an observable value.
    public func bind(_ cb: @escaping (Event) -> Void) -> Subscription {
        let observer = observeValues(cb)
        cb(data)
        return observer
    }
}

#endif // !RxSwift
