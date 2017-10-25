import Foundation

// swiftlint:disable type_name

// MARK: ViewModel

/// Protocol representing the view model type, acting acting as the business logic layer providing the necessary data
/// and methods for `View` binding and responding to user actions.
///
/// This interface is shared by both ViewModel and SelectionViewModel and most application code should refer to one of
/// those more specific protocols.
public protocol ViewModelType {

    /// Access to the underlying `Context`.
    var context: Context { get }

    /// Returns the `Action` that should be fired for a given `ViewModelUserEvent`. The default implementation returns
    /// nil.
    func actionForUserEvent(_ event: ViewModelUserEvent) -> Action?

    /// An array of secondary actions - typically displayed as a context menu or long-press menu depending on platform.
    /// Default implementation returns an empty list.
    func secondaryActions(for event: ViewModelUserEvent) -> [SecondaryAction]

    /// Returns `true` if the target view model type can handle the given user event, `false` if it cannot.
    ///
    /// The default implementation calls secondaryActions(for:) for .secondaryClick events and returns `true` if the
    /// result is not-empty, for all other event types it calls actionForUserEvent(_:) and returns `true` if the
    /// function returns any non-nil action.
    func canHandleUserEvent(_ event: ViewModelUserEvent) -> Bool

    /// Invoked on the view model when the view layer wants it to handle a given user event. The default implementation
    /// sends the action from action(_:) to the context. For most usecases implementing this is unnecessary.
    func handleUserEvent(_ event: ViewModelUserEvent)
}

/// Protocol representing a view model type, acting as the business logic layer above a `Model` and providing the
/// necessary data and methods for `View` binding.
///
/// All logic that would traditionally go in a UIView lives in this class: tap handling, sending actions, analytics,
/// interaction behaviors, etc. `View`s remain as lightweight as possible so that the functionality can be
/// unit tested without the actual view.
///
/// `ViewModel`s are typically instantiated by a `ViewModelBindingProvider` automatically as part of a UX-layer
/// binding step.
///
/// Ideally, view models should be value-types, but may be reference-types if identity/state is required.
public protocol ViewModel: ViewModelType {
    init(model: Model, context: Context)
}

/// Protocol representing a collection of one or more view models that respresent a user selection and can provide
/// customizable handling of user actions based on the selection and context.
public protocol SelectionViewModel: ViewModelType {
    /// Initialize with a collection of view models.
    init(viewModels: [ViewModel], context: Context)
}

/// Default implementations so `ViewModel`s may opt-in to only interactions they care about.
public extension ViewModelType {

    func actionForUserEvent(_ event: ViewModelUserEvent) -> Action? {
        return nil
    }

    func handleUserEvent(_ event: ViewModelUserEvent) {
        actionForUserEvent(event)?.send(from: context)
    }

    func canHandleUserEvent(_ event: ViewModelUserEvent) -> Bool {
        if .secondaryClick == event {
            return !secondaryActions(for: event).isEmpty
        } else {
            return actionForUserEvent(event) != nil
        }
    }

    func secondaryActions(for event: ViewModelUserEvent) -> [SecondaryAction] {
        return []
    }
}
