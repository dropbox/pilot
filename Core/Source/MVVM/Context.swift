import Foundation
import RxSwift

/// An object underlying the Pilot MVVM stack which:
///
/// 1. Acts as the primary application pathway for sending actions (implementing `ActionSender`).
/// 2. Provides dependencies and contextual state for the MVVM stack.
///
/// ## Receiving Actions
///
/// Typically, an application defines a root `Context` object at its top level (e.g. in the application
/// delegate on iOS). This context is then used when binding `Model`s to `ViewModel`s and `ViewModel`s to `Views` (this
/// is automatically taken care of when using PilotUI components like `CollectionViewController`).
///
/// To listen for a specific action on a context, it is recommended to use the `receive` method as follows:
///
/// ```
/// observer = context.receive { (action: MyAction) in
///     // Handle action here.
///      return .handled
/// }
/// ```
///
/// When the returned `Observer` object is deallocated, the receive closure will no longer be called. `receive` is a
/// typed action handler method that doesn't require an explicit call to stop listening and is therefore recommended
/// over calling `addReceiver` and `removeReceiver`. `receiveAll` invokes a closure for all actions on a target context.
/// It is typically used when a given object wants to listen for multiple actions.
///
/// Returning `.handled` will stop any further processing of that action. Returning `.notHandled` will cause the
/// `Context` to keep exhaustively looking for receivers to handle the action.
///
/// ## Sending Actions
///
/// The `Context` object implements `ActionSender` and is typically used for sending all application actions.
///
/// ```
/// // Preferred method of sending actions:
/// MyAction().send(from: context)
/// // Although this is acce
/// ```
///
/// ## Scopes
///
/// Any `Context` object may have parent or child "scopes". Scopes are primarily intended to logically layer action
/// handling so that lower-level scopes are checked first before bubbling actions up to higher level scopes.
///
/// As an example, an application may have a `UserTapped` action (sent by a `UserViewModel`). The top-level `Context`
/// may receive that action and navigate the user interface to show a "User Profile" screen. However, that same
/// application may have a control that selects a set of users for messaging. The same `UserViewModel` may send a
/// `UserTapped` action, but the control would want to intercept that action to add the user to a list, instead of
/// navigating. This is where scopes come into play. When creating and displaying the "User Picker" control, the
/// application would give it a new scope (via `context.newScope()`) so that actions in the scope of the user picker
/// control may be interpreted and handled differently.
///
/// ## Action Ordering
///
/// There is a deterministic ordering for evaluating which receiver handles an action sent on a context:
///
/// 1. Calls to `receive` or `addReceiver` add the observation closures to a stack. These closures on the stack are
/// evaluated in reverse order (i.e. last-to-first/top-down).
/// 2. If no closure returns `.handled`, then the action is sent to the `Context' object's parent scope `Context`.
/// 3. This continues until the action is handled. If not handled, a warning log is printed.
open class Context: ActionSender {

    // MARK: Init

    public init(
        parentScope: Context? = nil,
        navigatingUserEvents: Set<ViewModelUserEvent> = [.select]
    ) {
        self.parentScope = parentScope
        self.navigatingUserEvents = navigatingUserEvents
    }

    // MARK: Public: Scopes

    /// Returns a `Context` object which is a child scope of the target `Context`.
    open func newScope() -> Context {
        return Context(parentScope: self, navigatingUserEvents: navigatingUserEvents)
    }

    /// Returns a `Context` object which is a child scope of the target `Context`.
    open func newScope(with navigatingUserEvents: Set<ViewModelUserEvent>) -> Context {
        return Context(parentScope: self, navigatingUserEvents: navigatingUserEvents)
    }

    /// Returns the parent scope, if there is one.
    public let parentScope: Context?

    // MARK: Public: User Events

    /// Contains the set of `ViewModelUserEvent`s that can be considered a "navigate" in the current context. For
    /// example, in a menu or popover window, could be `.click` and `.enterKey` - or in a normal collection context
    /// would be `.select`.
    ///
    /// Example usage in a `ViewModel`:
    /// ```
    /// public func handleUserEvent(_ event: ViewModelUserEvent) {
    ///     guard context.shouldNavigate(for: event) else { return }
    ///     MyNavigateAction().send(from: context)
    /// }
    /// ```
    public let navigatingUserEvents: Set<ViewModelUserEvent>

    /// Determines if the context indicates that the given `ViewModelUserEvent` should consititute a navigation action.
    open func shouldNavigate(for event: ViewModelUserEvent) -> Bool {
        return navigatingUserEvents.contains(event)
    }

    // MARK: Public: Receiving Actions

    /// Registers a receiver for a specific `Action` type and returns an `Observer` which automatically unregisters
    /// the receiver upon deallocation. See documentation on `Context` for more details.
    public func receive<T: Action>(
        file: String = #file,
        line: Int = #line,
        _ handler: @escaping (T) -> ActionResult
    ) -> Disposable {
        let token = addReceiver(file: file, line: line) { action in
            if let typedAction = action as? T {
                return handler(typedAction)
            }
            return .notHandled
        }
        return Disposables.create { [weak self] in
            self?.removeReceiver(with: token)
        }
    }

    /// Registers a receiver for all `Action` types. Typically used by types that need to receive many types of actions.
    public func receiveAll(file: String = #file, line: Int = #line, _ handler: @escaping ActionReceiver) -> Disposable {
        let token = addReceiver(file: file, line: line) { action in
            return handler(action)
        }
        return Disposables.create { [weak self] in
            self?.removeReceiver(with: token)
        }
    }

    /// Adds an `ActionReceiver` to be invoked for any sent actions (in reverse-registration order). The receiver must
    /// be removed when no longer needed via `removeReceiver`. It is recommended to instead use `receive` to avoid
    /// bookkeeping of the returned `Token`.
    public func addReceiver(file: String = #file, line: Int = #line, _ receiver: @escaping ActionReceiver) -> Token {
        let description = "\(file):\(line)"
        let pair: Receiver = (Token.makeUnique(), receiver, description: description)
        lock.locked { receiverStack.append(pair) }
        return pair.0
    }

    /// Removes a previously-registered `ActionReceiver`.
    public func removeReceiver(with token: Token) {
        lock.locked { receiverStack = receiverStack.filter { $0.0 != token } }
    }

    // MARK: ActionSender

    @discardableResult
    open func send(_ action: Action) -> ActionResult {
        precondition(Thread.isMainThread, "`Context.send` must run on main thread")

        if let compound = action as? CompoundAction {
            var result: ActionResult = .notHandled
            for action in compound.actions {
                if case .handled = send(action) {
                    result = .handled
                }
            }
            return result
        }

        let reversedReceivers = lock.locked { receiverStack.reversed() }
        for receiverPair in reversedReceivers {
            let receiver = receiverPair.1
            if .handled == receiver(action) {
                let caller = receiverPair.description
                let domain = Log.Category.domain("Pilot.Context")
                Log.verbose(domain, message: "Action \(type(of:action)) handled by receiver added at: \(caller)")
                return .handled
            }
        }
        if let parentScope = parentScope {
            return parentScope.send(action)
        }
        Log.warning("pilot", message: "Unhandled action in Context: \(action)")
        return .notHandled
    }

    // MARK: Private

    private typealias Receiver = (Token, ActionReceiver, description: String)
    private var receiverStack: [Receiver] = []
    private let lock = Mutex()
}
