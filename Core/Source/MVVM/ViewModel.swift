import Foundation

// swiftlint:disable type_name

// MARK: ViewModel


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
public protocol ViewModel {

    init(model: Model, context: Context)

    /// Access to the underlying `Context`.
    var context: Context { get }

    // MARK: Interactions

    /// Returns `true` if the target view model type can handle the given user event, `false` if it cannot. The default
    /// implementation returns `true` for everything.
    func canHandleUserEvent(_ event: ViewModelUserEvent) -> Bool

    /// Invoked on the view model when the view layer wants it to handle a given user event.
    func handleUserEvent(_ event: ViewModelUserEvent)

    // MARK: Actions

    /// An array of secondary actions - typically displayed as a context menu or long-press menu depending on platform.
    func secondaryActions(for event: ViewModelUserEvent) -> [SecondaryAction]
}

/// Event types that view models may handle, typically sent from the view layer.
public enum ViewModelUserEvent {
    /// On mouse-supporting platforms, represents a click by the user.
    case click

    /// Represents the user typing enter/return.
    case enterKey

    /// Represents the user typing space.
    case spaceKey

    /// Reprsents the user performing a long-press on the target view model.
    case longPress

    /// On mouse-supporting platforms, represents a secondary (right) click by the user.
    case secondaryClick

    /// On any platform, represents the target being selected (via mouse, programatically, or tap).
    case select

    /// On touch platforms, represents the target receiving a single tap.
    case tap
}

/// Wraps an `Action` with additional data to be rendered in a "secondary" context like context menus or long-press
/// menus.
public struct SecondaryActionInfo {

    public init(action: Action, title: String, state: State = .off, enabled: Bool = true, event: AnalyticsEvent? = nil) {
        self.action = action
        self.title = title
        self.state = state
        self.enabled = enabled
        self.event = event
    }

    /// State of the secondary action. Note that this differs from enabled, but instead represents whether the action
    /// is "checked" in a list.
    public enum State {
        case on
        case off
        case mixed
    }

    public let action: Action
    public let title: String
    public let state: State
    public let enabled: Bool
    public let event: AnalyticsEvent?
}

/// Represents a secondary action to be displayed in a list to the user (typically from right-click or long-press).
public enum SecondaryAction {
    case action(SecondaryActionInfo)
    case info(String)
    case separator
}

/// Default implementations so `ViewModel`s may opt-in to only interactions they care about.
public extension ViewModel {

    func handleUserEvent(_ event: ViewModelUserEvent) {}

    func canHandleUserEvent(_ event: ViewModelUserEvent) -> Bool {
        return true
    }

    func secondaryActions(for event: ViewModelUserEvent) -> [SecondaryAction] {
        return []
    }
}

// MARK: Binding

/// An optional protocol that types may adopt in order to provide a `ViewModel` directly. This is the default method
/// `ViewModelBindingProvider` uses to instantiate a `ViewModel`.
public protocol ViewModelConvertible {

    /// Return a `ViewModel` representing the target type.
    func viewModelWithContext(_ context: Context) -> ViewModel
}

/// Core binding provider protocol to generate `ViewModel` instances from `Model` instances.
public protocol ViewModelBindingProvider {

    /// Returns a `ViewModel` for the given `Model` and context.
    func viewModel(for model: Model, context: Context) -> ViewModel
}

/// A `ViewModelBindingProvider` which provides default behavior to check the `Model` for conformance to
/// `ViewModelConvertible`.
public struct DefaultViewModelBindingProvider: ViewModelBindingProvider {

    public init() {}

    // MARK: ViewModelBindingProvider

    public func viewModel(for model: Model, context: Context) -> ViewModel {
        guard let convertible = model as? ViewModelConvertible else {
            // Programmer error to fail to provide a binding.
            // - TODO:(wkiefer) Avoid `fatalError` for programmer binding errors - return default empty views & assert.
            fatalError(
                "Default ViewModel binding requires model to conform to `ViewModelConvertible`: \(type(of: model))")
        }
        return convertible.viewModelWithContext(context)
    }
}
