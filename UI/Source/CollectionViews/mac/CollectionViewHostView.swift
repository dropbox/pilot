import AppKit
import Pilot

/// `NSCollectionViewItem` subclass which provies hosting for a given `View`.
/// - Note: Because items are `NSView`s, the `View` must also be a `NSView` for hosting to be supported.
public final class CollectionViewHostView: NSView {

    // MARK: Public

    // The hosted `View` instance.
    public var hostedView: View? {
        willSet {
            if let view = hostedView as? NSView {
                if let newValue = newValue as? NSView , newValue.classForCoder == view.classForCoder {
                    // NOOP: The view classes are the same, so no need to remove.
                } else {
                    // TODO:(wkiefer) This also needs to unbind here (see TODO in the data source)
                    view.removeFromSuperview()
                }
            }
        }
        didSet {
            // Only add the view if it isn't already added (i.e. hit the noop case in `willSet`.)
            if let theView = hostedView as? NSView , theView.superview != self {
                addSubview(theView)
                theView.translatesAutoresizingMaskIntoConstraints = false
                theView.constrain(edgesEqualToView: self)
            }
        }
    }
}
