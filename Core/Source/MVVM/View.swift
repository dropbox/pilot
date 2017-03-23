import Foundation
import QuartzCore

// NOTE: This file defines the abstract concept of a view. But because it is in Pilot, there is no actual dependency
// on any platform-specific view implementation. i.e. Do not import UIKit or AppKit here.

/// Protocol defining an application-defined view object which binds and displays the data from a `ViewModel`
/// (typically a `UIView` or `NSView`).
///
/// `View`s representing view model objects can be hosted in various contexts: as content for collection view
/// cells, table view cells, popovers, static views, any any other situation. Some of these contexts support additional
/// `View` methods defined by that context below.
public protocol View: class {

    /// `View` instances are often instantiated directly from their type, so all implementations must conform to
    /// the default initializer.
    init()

    /// The associated `ViewModel` represented by this type.
    var viewModel: ViewModel? { get }

    /// Binds the target type to the given `ViewModel` and updates its UI. Typically invoked by a
    /// `ViewBindingProvider`. Implementations should set `viewModel` during this method.
    func bindToViewModel(_ viewModel: ViewModel)

    /// Unbinds the target from the previously-bound `ViewModel`. Should update the UI to a blank state and set
    /// `viewModel` back to `nil`.
    func unbindFromViewModel()

    /// Invoked by view binding systems before the view will be laid out with the given available size. The `object`
    /// argument allows the caller to provide any context to the view that may affect its layout. For example it's
    /// position in a collection view, or information about the preceding view.
    func willLayoutWithAvailableSize(_ availableSize: AvailableSize, with object: Any?)

    /// Returns the preferred layout for the given `viewModel` if rendered by this `View`. This is a static method
    /// for optimized performance so view size estimation does not require an actual bound instance of a view. The 
    /// `object` argument allows the caller to provide any context to the view that may affect its layout. For
    /// example it's position in a collection view, or information about the preceding view.
    static func preferredLayout(
        fitting availableSize: AvailableSize,
        for viewModel: ViewModel,
        with object: Any?
    ) -> PreferredLayout

    /// Applies the given `ViewLayout` to the target view type. This is the same `ViewLayout` object as returned by
    /// `preferredLayout:fitting:for` and is passed back to the view by the binding
    /// mechanisms to allow for optimized layout.
    /// This is an optional/advanced option for views to optimize layout passes, typically used for complicated
    /// hierarchies or variable sized collections.
    func applyLayout(_ layout: ViewLayout)

    /// Invoked when the target view is a child of a control that supports selection. Typically used by views hosted
    /// in collections and tables.
    var selected: Bool { get set }

    /// Invoked when the highlight state of the target view should change. This is typically used when the target view
    /// is hosted in a control or collection where highlighting via clicking/tapping is possible.
    var highlightStyle: ViewHighlightStyle { get set }
}

/// Represents the binding from a ViewModel to a View.
public struct ViewBinding {
    public init<T: View>(_ viewType: T.Type) {
        self.viewType = viewType
        generate = { $0 as? T ?? viewType.init() }
    }

    public let viewType: View.Type
    public let generate: (View?) -> View
}

/// Provider protocol for binding and unbinding `View`s with `ViewModel`s.
public protocol ViewBindingProvider {

    /// Returns a ViewBinding which describes the appropriate `View` for the given `ViewModel`.
    func viewBinding(for viewModel: ViewModel, context: Context) -> ViewBinding

    /// Returns a bound `View` for the given `ViewModel`. `reuseView`, when provided, is an already-allocated
    /// instance of the same view class, provided as an optimization to avoid creating a new instance when possible.
    func view(
        for viewModel: ViewModel,
        context: Context,
        reusing reuseView: View?,
        layout: ViewLayout?
    ) -> View

    /// Unbinds the given `View` from its previously-bound `ViewModel`.
    func unbind(_ view: View)

    /// Returns the preferred layout for the given view model, if applicable. This method allows view binding
    /// implementations to have model->view specific mapping logic help determine the preferred size.
    ///
    func preferredLayout(
        fitting availableSize: AvailableSize,
        for viewModel: ViewModel,
        context: Context
    ) -> PreferredLayout
}

public extension ViewBindingProvider {

    /// Default implementation of `unbind`.
    func unbind(_ view: View) {
        precondition(view.viewModel != nil, "Attempt to unbind view that has no view model.")
        view.unbindFromViewModel()
        assertWithLog(view.viewModel == nil, message: "View model for view is not nil after unbinding.")
    }

    func viewTypeForViewModel(_ viewModel: ViewModel, context: Context) -> View.Type {
        return viewBinding(for: viewModel, context: context).viewType
    }

    /// Default implementation. It grabs the binding from bindingForViewModel and uses it to construct
    /// a new View, optionally reusing the existing view if possible.
    func view(
        for viewModel: ViewModel,
        context: Context,
        reusing reuseView: View?,
        layout: ViewLayout?
    ) -> View {
        let binding = viewBinding(for: viewModel, context: context)
        let view: View = binding.generate(reuseView)
        view.bindToViewModel(viewModel)
        if let layout = layout {
            view.applyLayout(layout)
        }
        return view
    }

    /// Default implementation of `preferredLayout(fitting:with:context)`.
    func preferredLayout(
        fitting availableSize: AvailableSize,
        for viewModel: ViewModel,
        context: Context
    ) -> PreferredLayout {
        let viewType = viewTypeForViewModel(viewModel, context: context)
        return viewType.preferredLayout(fitting: availableSize, for: viewModel, with: context)
    }
}

/// Enum which encompases an optional preferred size.
public enum PreferredLayout: Equatable {
    /// No preferred size.
    case none

    /// Preferred size contained in associated data.
    case Size(CGSize)

    /// Opaque object representing the actual layout of the `View`. This calculated object can be passed to the
    /// `View` later as a performance optimization so it doesn't have to be recalculated.
    case Layout(ViewLayout)

    /// Returns the preferred size, or nil if none.
    public var size: CGSize? {
        switch self {
        case .none:
            return nil
        case .Layout(let layout):
            return layout.size
        case .Size(let size):
            return size
        }
    }

    /// Returns the associated `ViewLayout` type, or nil if not applicable.
    public var layout: ViewLayout? {
        switch self {
        case .Layout(let layout):
            return layout
        default:
            return nil
        }
    }
}

public enum ViewHighlightStyle {
    /// Highlight is in preperation for selection.
    case selection

    /// Highlight is in preperation for deselection.
    case deselection

    /// Highlight during a right-click context menu operation.
    case contextMenu

    /// Highlight during a drag-drop operation.
    case drop

    /// No highlight.
    case none

    /// Returns a lower fidelity mapping to a `highlighted` `Bool` found in many other APIs.
    public var highlighted: Bool {
        switch self {
        case .selection, .contextMenu, .drop:
            return true
        case .deselection, .none:
            return false
        }
    }
}

public func == (lhs: PreferredLayout, rhs: PreferredLayout) -> Bool {
    switch (lhs, rhs) {
    case (.none, .none):
        return true
    case (.Size(let left), .Size(let right)):
        return left.equalTo(right)
    case (.Layout(let left), .Layout(let right)):
        return left.size.equalTo(right.size)
    default:
        return false
    }
}

/// Struct representing the available size for layout given to a `View`. It holds two specific sizes to
/// differentiate between the maximum allowed size and the size the view will be if it has a `PreferredLayout.None`.
/// `View`s may decide to use the `defaultSize` as a target size to try to get close to when possible.
public struct AvailableSize {
    public var defaultSize: CGSize
    public var maxSize: CGSize

    public init(defaultSize: CGSize, maxSize: CGSize) {
        self.defaultSize = defaultSize
        self.maxSize = maxSize
    }

    public init(_ size: CGSize) {
        self.defaultSize = size
        self.maxSize = size
    }

    /// Returns a new AvailableSize where both `defaultSize` and `maxSize` are shrunk to be less than or equal to `max`.
    public func constrain(_ max: CGSize) -> AvailableSize {
        let constrainedDefault = CGSize(
            width: min(defaultSize.width, max.width),
            height: min(defaultSize.height, max.height))
        let constrainedMax = CGSize(
            width: min(maxSize.width, max.width),
            height: min(maxSize.height, max.height))
        return AvailableSize(defaultSize: constrainedDefault, maxSize: constrainedMax)
    }
}

/// Default implementations of view-specific methods so that all `Views` don't have to support specific scenarios
/// that they may not need.
public extension View {

    public func willLayoutWithAvailableSize(_ availableSize: AvailableSize, with object: Any? = nil) { }

    public func applyLayout(_ layout: ViewLayout) {}

    public static func preferredLayout(
        fitting availableSize: AvailableSize,
        for viewModel: ViewModel,
        with object: Any? = nil
    ) -> PreferredLayout {
        return .none
    }

    public var selected: Bool {
        get { return false }
        set {}
    }

    public var highlightStyle: ViewHighlightStyle {
        get { return .none }
        set {}
    }
}
