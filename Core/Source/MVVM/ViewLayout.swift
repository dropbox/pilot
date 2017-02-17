import Foundation
import QuartzCore

/// Protocol representing the opaque data representing the layout for a particular `View`. The only exposed property
/// is the total size used by the data binding systems.
public protocol ViewLayout {

    /// Total required size of the layout for the associated `View`. This translates to `frame.size` for view types
    /// that have frames.
    var size: CGSize { get }

    /// Called to check if a cached ViewLayout is still valid for rendering a viewModel. Return false to invalidate.
    func validCache(forViewModel viewModel: ViewModel) -> Bool
}

extension ViewLayout {
    public func validCache(forViewModel viewModel: ViewModel) -> Bool { return true }
}
