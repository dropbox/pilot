import Foundation

public typealias ObserverToken = Token

/// Protocol for any object that is observable for a given associated `Event` type (typically an enum with associated
/// data).
/// TODO:(wkiefer) Expand docs here - explain benefit of block-based observer which allows non-class observation.
public protocol ObservableType: class {
    associatedtype Event

    /// Adds the given observer to the target type. A object conforming to `Subscription` is returned, which must be
    /// retained observing using the `unsubscribe()`.
    func observeValues(_ observer: @escaping (Event) -> Void) -> Subscription
}

/// The GenericObservable<Event> is a "protocol" that allows use of the associated Event
/// type as a type argument.  This works around some limitations in Swift generics, and if Swift
/// gains the ability to to constrain use of a protocol by its specific associated types, then this
/// "protocol" will no longer be necessary.
/// See https://gist.github.com/chadaustin/74786d6ca3c34bba8b33af381606b207 for what
/// this might look like.
/// NOTE: does not expose the notifyObserversOfEvent method because this is read-only.
open class Observable<Event>: ObservableType {
    public init() {}
    open func observeValues(_ observer: @escaping (Event) -> Void) -> Subscription {
        Log.fatal(message: "observeValues(_:) must be overridden")
    }
}

/// ProxyingObservable is the easiest way to implement the Observable protocol.  A demonstration:
///
/// ```swift
/// class MyThing: ProxyingObservable {
///   public typealias Event = MyEventType
///   public var proxiedObservable: GenericObservable<Event> { return observers }
///   private let observers = ObserverList<Event>()
/// }
/// ```
///
/// Implementing ProxyingObservable gives your class `addObserver`, `removeObserver`, and
/// `observe` for free.
/// The implementation should call `observers.notify` to fire an event to its observers.
public protocol ProxyingObservable: ObservableType {
    var proxiedObservable: Observable<Event> { get }
}

/// The default Observable implementations on ProxyingObservable.
public extension ProxyingObservable {
    public func observeValues(_ observer: @escaping (Event) -> Void) -> Subscription {
        return proxiedObservable.observeValues(observer)
    }
}

/// A concrete, writeable implementation of ObserverList and thus Observer.
/// Use the `notify` method to fire an event to all of the observers.
public final class ObserverList<Event>: Observable<Event> {
    public override init() {
        self.observers = [:]
    }

    public override func observeValues(_ observer: @escaping (Event) -> Void) -> Subscription {
        let token = Token.makeUnique()
        lock.locked { self.observers[token] = observer }
        return Subscription {
            self.lock.locked { self.observers[token] = nil }
        }
    }

    public func notify(_ event: Event) {
        precondition(Thread.isMainThread, "notify must run on main thread")
        /// Create a local array in case notification causes an observer to be removed.
        let observerValues = lock.locked { self.observers.values }
        for observer in observerValues {
            observer(event)
        }
    }

    private var observers: [ObserverToken: (Event) -> Void]
    private let lock = Mutex()
}
