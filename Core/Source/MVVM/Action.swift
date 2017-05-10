import Foundation

/// A type that represents a desired change in application state, user interaction, data store change, external service
/// request, or any other application-level event that needs to bubble up to a higher layer of the application for
/// handling. The `Action` itself contains only the data needed to perform some change -- an `ActionReceiver` is
/// responsible for actual handling of the event represented by the `Action`.
///
/// The Pilot MVVM stack has unidirectional data flow, and `Action`s are the only way to send events back from the
/// `View`/`ViewModel` layers to higher-level application objects (like the responder chain on iOS/macOS).
/// Typically `ViewModel` types respond to a user event by creating an `Action` and sending it via `Context`.
public protocol Action {
    // This space intentionally left blank to support future `Action` behavior as the breadth of Pilot increases to
    // support stores and services.
}

public extension Action {


    /// Convenience method to send an action with the given `sender`. e.g.
    /// ```
    ///   MyAction().send(from: context)
    ///
    /// // as a more readable alternative to:
    ///   context.send(MyAction())
    /// ```
    @discardableResult
    func send(from sender: ActionSender) -> ActionResult {
        return sender.send(self)
    }
}

/// Protocol defining a type that can send `Action` types. The ideal implementation is in `Context` - but
/// applications or test frameworks may define their own send pathways if desired.
public protocol ActionSender {

    @discardableResult
    func send(_ action: Action) -> ActionResult
}

/// Typealias for a closure that handles an `Action` producing an `ActionResult`.
public typealias ActionReceiver = (Action) -> ActionResult

/// Result type for actions.
public enum ActionResult {
    /// The `Action` was handled by the target `ActionResponder`.
    case handled
    /// The `Action` was not handled by any `ActionResponder`.
    case notHandled
}
