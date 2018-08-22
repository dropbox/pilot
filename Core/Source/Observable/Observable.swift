import Foundation

public typealias ObserverToken = Token

public class Observable<Element>: ObservableType {
    public typealias E = Element

    public func asObservable() -> Observable<Element> { return self }

    public func subscribe<O>(_ observer: O) -> Disposable where O : ObserverType, Element == O.E {
        Log.fatal(message: "subscribe is an abstract method and must be overridden")
    }
}

/// Protocol for any object that is observable for a given associated `Event` type (typically an enum with associated
/// data).
/// TODO:(wkiefer) Expand docs here - explain benefit of block-based observer which allows non-class observation.
public protocol ObservableType: class {
    associatedtype E

    func subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E
}

public protocol Disposable {
    func dispose()
}

public protocol ObserverType {
    associatedtype E
    func on(_ event: Event<E>)
}

public enum Event<Element> {
    /// Next element is produced.
    case next(Element)

    /// Sequence terminated with an error.
    case error(Swift.Error)

    /// Sequence completed successfully.
    case completed
}

/// The GenericObservable<Event> is a "protocol" that allows use of the associated Event
/// type as a type argument.  This works around some limitations in Swift generics, and if Swift
/// gains the ability to to constrain use of a protocol by its specific associated types, then this
/// "protocol" will no longer be necessary.
/// See https://gist.github.com/chadaustin/74786d6ca3c34bba8b33af381606b207 for what
/// this might look like.
/// NOTE: does not expose the notifyObserversOfEvent method because this is read-only.
//open class GenericObservable<Event>: Observable {
//    public init() {}
//    open func addObserver(_ observer: @escaping (Event) -> Void) -> ObserverToken {
//        Log.fatal(message: "addObserver must be overridden")
//    }
//    open func removeObserver(with token: ObserverToken) {
//        Log.fatal(message: "removeObserverWithToken must be overridden")
//    }
//}

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
//public protocol ProxyingObservable: Observable {
//    var proxiedObservable: GenericObservable<Event> { get }
//}

/// The default Observable implementations on ProxyingObservable.
//public extension ProxyingObservable {
//    public func addObserver(_ observer: @escaping (Event) -> Void) -> ObserverToken {
//        return proxiedObservable.addObserver(observer)
//    }
//    public func removeObserver(with token: ObserverToken) {
//        return proxiedObservable.removeObserver(with: token)
//    }
//}

/// A concrete, writeable implementation of ObserverList and thus Observer.
/// Use the `notify` method to fire an event to all of the observers.
//public final class ObserverList<Event>: GenericObservable<Event> {
//    public override init() {
//        self.observers = [:]
//    }
//
//    public override func addObserver(_ observer: @escaping (Event) -> Void) -> ObserverToken {
//        let token = Token.makeUnique()
//        lock.locked { self.observers[token] = observer }
//        return token
//    }
//
//    public override func removeObserver(with token: ObserverToken) {
//        lock.locked { self.observers[token] = nil }
//    }
//
//    public func notify(_ event: Event) {
//        precondition(Thread.isMainThread, "notify must run on main thread")
//        /// Create a local array in case notification causes an observer to be removed.
//        let observerValues = lock.locked { self.observers.values }
//        for observer in observerValues {
//            observer(event)
//        }
//    }
//
//    private var observers: [ObserverToken: (Event) -> Void]
//    private let lock = Mutex()
//}
//
///// The Observer class represents the binding of an observable to a function.  While
///// the Observer is alive, the function will be called.  When the Observer is deallocated,
///// it is automatically unregistered from the observable.  This prevents forgetting to remove
///// the observer and often avoids the need to write deinit implementations.
/////
///// NOTE: Observer holds a weak reference to the observed object.
/////
///// Usage:
/////
/////   // in init
/////   thingObserver = thing.observe { [weak self] in
/////     ...
/////   }
/////
/////   // as property
/////   private let thingObserver: Observer?
/////
///// Sometimes you want to hold the Observer in an optional, sometimes not, depending on
///// whether the field is constructed by default.
//public final class Observer {
//    internal init(_ remover: @escaping () -> Void) {
//        self.remover = remover
//    }
//
//    deinit {
//        remover()
//    }
//
//    private let remover: () -> Void
//}
//
//public extension Observable {
//
//    public func observe(_ handler: @escaping (Event) -> Void) -> Observer {
//        let token = addObserver(handler)
//        return Observer { [weak self] in
//            self?.removeObserver(with: token)
//        }
//    }
//}
