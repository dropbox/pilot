import Foundation

/// Enumeration of available system queues.
public enum Queue {
    case main
    case userInteractive
    case userInitiated
    case utility
    case background
    case custom(DispatchQueue)

    /// Create a new serial queue with the given label.
    public static func createSerial(_ label: String) -> Queue {
        return .custom(DispatchQueue(label: label, attributes: []))
    }

    /// Returns the GCD dispatch queue for the target type.
    public func toDispatch() -> DispatchQueue {
        switch self {
        case .main:
            return DispatchQueue.main
        case .userInteractive:
            return DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)
        case .userInitiated:
            return DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)
        case .utility:
            return DispatchQueue.global(qos: DispatchQoS.QoSClass.utility)
        case .background:
            return DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        case .custom(let queue):
            return queue
        }
    }
}

/// Issue a precondition failure if we are not currently running on the specified queue, at least as far as we can
/// distinguish via its label.
public func preconditionOnQueue(_ queue: Queue) {
    if #available(iOS 10, OSX 10.12, *) {
        dispatchPrecondition(condition: .onQueue(queue.toDispatch()))
    }
}

/// Convenience type wrapping common asynchronous dispatch queue operations. Single operations are supported:
/// ```swift
/// Async.onBackground {
///     // Do work...
/// }
/// ```
///
/// And dependent-chaining is supported:
/// ```swift
/// Async.onBackground {
///     // Do 'work 1'.
/// }.onMain {
///     // This will happen after 'work 1' on the main thread.
/// }
/// ```
public struct Async {

    // MARK: Static Convenience Methods

    @discardableResult
    public static func onMain(_ block: @escaping ()->()) -> Async {
        return dispatch(queue: .main, block: block)
    }

    @discardableResult
    public static func onUserInteractive(_ block: @escaping ()->()) -> Async {
        return dispatch(queue: .userInteractive, block: block)
    }

    @discardableResult
    public static func onUserInitiated(_ block: @escaping ()->()) -> Async {
        return dispatch(queue: .userInitiated, block: block)
    }

    @discardableResult
    public static func onUtility(_ block: @escaping ()->()) -> Async {
        return dispatch(queue: .utility, block: block)
    }

    @discardableResult
    public static func onBackground(_ block: @escaping ()->()) -> Async {
        return dispatch(queue: .background, block: block)
    }

    @discardableResult
    public static func on(_ customQueue: Queue, block: @escaping ()->()) -> Async {
        return dispatch(queue: customQueue, block: block)
    }

    @discardableResult
    public static func on(_ queue: Queue, waitingFor group: DispatchGroup, block: @escaping ()->()) -> Async {
        return dispatchWaitingFor(dispatchGroup: group, dispatchQueue: queue.toDispatch(), block)
    }

    // MARK: Chained Convenience Methods

    @discardableResult
    public func onMain(_ block: @escaping ()->()) -> Async {
        return dispatch(queue: .main, block: block)
    }

    @discardableResult
    public func onUserInteractive(_ block: @escaping ()->()) -> Async {
        return dispatch(queue: .userInteractive, block: block)
    }

    @discardableResult
    public func onUserInitiated(_ block: @escaping ()->()) -> Async {
        return dispatch(queue: .userInitiated, block: block)
    }

    @discardableResult
    public func onUtility(_ block: @escaping ()->()) -> Async {
        return dispatch(queue: .utility, block: block)
    }

    @discardableResult
    public func onBackground(_ block: @escaping ()->()) -> Async {
        return dispatch(queue: .background, block: block)
    }

    @discardableResult
    public func on(_ customQueue: Queue, block: @escaping ()->()) -> Async {
        return dispatch(queue: customQueue, block: block)
    }

    // MARK: Core Methods

    @discardableResult
    public static func dispatch(queue: Queue, block: @escaping ()->()) -> Async {
        return dispatch(queue.toDispatch(), block)
    }

    @discardableResult
    public func dispatch(queue: Queue, block: @escaping ()->()) -> Async {
        return dispatchDependentBlock(queue.toDispatch(), block)
    }

    // MARK: Private

    private let group: DispatchGroup

    private init(_ group: DispatchGroup) {
        self.group = group
        group.notify(queue: .global(qos: .utility)) {
            _ = group
        }
    }

    private static func dispatch(_ dispatchQueue: DispatchQueue, _ block: @escaping ()->()) -> Async {
        let group = DispatchGroup()
        group.enter()
        dispatchQueue.async {
            block()
            group.leave()
        }
        return Async(group)
    }

    private func dispatchDependentBlock(_ dispatchQueue: DispatchQueue, _ dependentBlock: @escaping ()->()) -> Async {
        let dependentGroup = DispatchGroup()
        dependentGroup.enter()
        group.notify(queue: dispatchQueue) {
            dependentBlock()
            dependentGroup.leave()
        }
        return Async(dependentGroup)
    }

    private static func dispatchWaitingFor(
        dispatchGroup: DispatchGroup,
        dispatchQueue: DispatchQueue,
        _ dependentBlock: @escaping ()->()
    ) -> Async {
        let wrapperGroup = DispatchGroup()
        wrapperGroup.enter()
        dispatchGroup.notify(queue: dispatchQueue) {
            dependentBlock()
            wrapperGroup.leave()
        }
        return Async(wrapperGroup)
    }
}

/// Async helper functions.
extension Async {

    /// Creates and returns a new debounced version of the passed `block` which will postpone its execution until after
    /// `wait` milliseconds have elapsed since the last time it was invoked. Useful for implementing behavior that
    /// should only happen after the input has stopped arriving. For example: rendering a preview of a Markdown comment,
    /// recalculating a layout after the window has stopped being resized, and so on.
    ///
    /// Example:
    ///
    /// ```
    /// userDidEnterText = debounce(wait: .milliseconds(100)) { renderPreview() }
    /// ```
    ///
    /// NOTE: This method must be called on the main thread.
    public static func debounce(wait interval: DispatchTimeInterval, block: @escaping () -> Void) -> () -> Void {
        precondition(Thread.isMainThread)

        var lastWorkItem: DispatchWorkItem?
        return {
            lastWorkItem?.cancel()
            let time: DispatchTime = DispatchTime.now()
            let nextWorkItem = DispatchWorkItem { lastWorkItem = nil; block() }
            DispatchQueue.main.asyncAfter(deadline: time, execute: nextWorkItem)
            lastWorkItem = nextWorkItem
        }
    }

    /// Creates and returns a new, throttled version of the passed `block`, that, when invoked repeatedly, will only
    /// call the original closure at most once per every `wait` milliseconds. Useful for rate-limiting events that
    /// occur faster than you can keep up with.
    ///
    /// Example:
    ///
    /// ```
    /// didRecieveLocationEvent = throttle(wait: .milliseconds(100)) { updateMapPosition() }
    /// ```
    ///
    /// NOTE: This method must be called on the main thread.
    public static func throttle(wait interval: DispatchTimeInterval, block: @escaping () -> Void) -> () -> Void {
        precondition(Thread.isMainThread)

        var resetThrottle: DispatchWorkItem?
        return {
            guard resetThrottle == nil else { return }
            DispatchQueue.main.async {
                let time: DispatchTime = DispatchTime.now() + interval
                let reset = DispatchWorkItem { resetThrottle = nil }
                resetThrottle = reset
                DispatchQueue.main.asyncAfter(deadline: time, execute: reset)
                block()
            }
        }
    }

    /// Creates a version of `block` that, when invoked repetedly with a collection, batches provided arguments.
    /// Batching is done using a reducer, and `block` will be called on the provided time interval (after it is called
    /// with some argument).
    /// - Note: The provided queue must be serial.
    public static func coalesce<T>(
        coalesceTime: DispatchTimeInterval,
        queue: Queue = .main,
        reducer: @escaping (T, T) -> T,
        block: @escaping (T) -> Void
    ) -> (T) -> Void {
        let dispatchQueue = queue.toDispatch()

        /// Contains the batched argument constructed so far.
        var batchedArgument: T?
        return { value in
            dispatchQueue.async {
                let firstValueSinceFlush = (batchedArgument == nil)

                if let batchedArgumentUnwrapped = batchedArgument {
                    batchedArgument = reducer(batchedArgumentUnwrapped, value)
                } else {
                    batchedArgument = value
                }

                if firstValueSinceFlush {
                    let time: DispatchTime = DispatchTime.now() + coalesceTime

                    dispatchQueue.asyncAfter(deadline: time, execute: DispatchWorkItem {
                        guard let unwrappedBatchedArgument: T = batchedArgument else {
                            preconditionFailure("Shouldn't have started a timer if there wasn't a set argument.")
                        }

                        block(unwrappedBatchedArgument)
                        batchedArgument = nil
                    })
                }
            }
        }
    }

    /// A wrapper around the coalesce function above. Handles the common case of coalescing a list of items.
    /// - Note: The provided queue must be serial.
    public static func coalesce<T>(
        coalesceTime: DispatchTimeInterval,
        queue: Queue = .main,
        block: @escaping ([T]) -> Void
    ) -> ([T]) -> Void {
        return coalesce(coalesceTime: coalesceTime, queue: queue, reducer: +, block: block)
    }

    /// A wrapper around the coalesce function above. Handles the common case of coalescing a set of items.
    /// - Note: The provided queue must be serial.
    public static func coalesce<T>(
        coalesceTime: DispatchTimeInterval,
        queue: Queue = .main,
        block: @escaping (Set<T>) -> Void
    ) -> (Set<T>) -> Void {
        let reducer = { (a: Set<T>, b: Set<T>) -> Set<T> in
            return a.union(b)
        }
        return coalesce(coalesceTime: coalesceTime, queue: queue, reducer: reducer, block: block)
    }
}
