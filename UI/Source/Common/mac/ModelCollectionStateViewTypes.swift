import AppKit

/// Struct representing what to display when the collection view is empty.
public enum EmptyCollectionDisplay {
    /// Returns a custom string with font and color, which is displayed in the center of the empty collection view.
    case text(String, NSFont, NSColor)

    /// Returns a custom view that will be centered in the empty collection view.
    case view(NSView)

    /// Returns a custom view and a custom constraint creation block to hook up constraints to the parent view.
    /// Paramaters of the closure are the parent view and the child view, in order. Return value is an
    /// array of constraints which will be added.
    case viewWithCustomConstraints(NSView, (NSView, NSView) -> [NSLayoutConstraint])

    /// No empty view.
    case none
}

/// Struct representing what spinner to display when the collection view is empty and loading.
/// TODO:(wkiefer) Bring this to iOS (and share where possible).
public enum LoadingCollectionDisplay {
    /// No loading view.
    case none

    /// Shows the default system spinner centered in the view.
    case systemSpinner

    /// Shows the default system spinner with the provided custom constraints.
    /// Paramaters of the closure are the parent view and the child view, in order. Return value is an
    /// array of constraints which will be added.
    case systemSpinnerWithConstraints((NSView, NSView) -> [NSLayoutConstraint])

    /// Shows a custom loading indicator view centered in the view.
    case custom(NSView)

    /// Shows a custom loading indicator view with the provided custom constraints.
    /// Paramaters of the closure are the parent view and the child view, in order. Return value is an
    /// array of constraints which will be added.
    case customWithConstraints(NSView, (NSView, NSView) -> [NSLayoutConstraint])
}
