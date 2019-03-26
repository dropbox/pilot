import AppKit
import Pilot

/// `NSCollectionViewItem` subclass which provies hosting for a given `View`.
/// - Note: Because items are `NSView`s, the `View` must also be an `NSView` or an `NSViewController`
/// for hosting to be supported.
public final class CollectionViewHostItem: NSCollectionViewItem {

    // MARK: Public

    // The hosted `View` instance.
    public var hostedView: View? {
        willSet {
            if let view = hostedView as? NSView {
                if let newValue = newValue as? NSView, newValue == view {
                    // NOOP: The view is the same, so no need to remove.
                } else {
                    // TODO:(wkiefer) This also needs to unbind here (see TODO in the data source)
                    view.removeFromSuperview()
                }
            } else if let vc = hostedView as? NSViewController {
                if let newValue = newValue as? NSViewController, newValue == vc {
                    // NOOP: The view is the same, so no need to remove.
                } else {
                    // TODO:(wkiefer) This also needs to unbind here (see TODO in the data source)
                    vc.view.removeFromSuperview()
                }
            }
        }
        didSet {
            // Only add the view if it isn't already added (i.e. hit the noop case in `willSet`.)
            if let theView = hostedView as? NSView, theView.superview != view {
                view.addSubview(theView)
                theView.translatesAutoresizingMaskIntoConstraints = false
                theView.constrain(edgesEqualToView: view)
            } else if let theVC = hostedView as? NSViewController, theVC.view.superview != view {
                view.addSubview(theVC.view)
                theVC.view.translatesAutoresizingMaskIntoConstraints = false
                theVC.view.constrain(edgesEqualToView: view)
            }

            // Preserve selection and highlight state across hostedView set.
            hostedView?.selected = oldValue?.selected ?? false
            hostedView?.highlightStyle = oldValue?.highlightStyle ?? .none

            // Preserve cachedLayoutAttributes across hostedView set.
            if let attribs = cachedLayoutAttributes, let cvt = hostedView as? CollectionSupportingView {
                cvt.apply(attribs)
            }

            menuTrackingCookie += 1
        }
    }

    /// Mapped to `hostedView?.highlightStyle`.
    public var highlightStyle: ViewHighlightStyle {
        get { return hostedView?.highlightStyle ?? .none }
        set { hostedView?.highlightStyle = newValue }
    }

    // MARK: NSViewController

    public override func loadView() {
        view = NSView()
        view.autoresizingMask = [NSView.AutoresizingMask.width, NSView.AutoresizingMask.height]
    }

    // MARK: NSCollectionViewElement

    public override func prepareForReuse() {
        super.prepareForReuse()

        menuTrackingCookie += 1
        highlightStyle = .none

        if let cvt = hostedView as? CollectionSupportingView {
            cvt.prepareForReuse()
        }
    }

    public override func apply(_ layoutAttributes: NSCollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        cachedLayoutAttributes = layoutAttributes

        if let cvt = hostedView as? CollectionSupportingView {
            cvt.apply(layoutAttributes)
        }
    }

    /// Mapped to `hostedView?.isSelected`.
    public override var isSelected: Bool {
        get { return hostedView?.selected ?? false }
        set { hostedView?.selected = newValue }
    }

    /// Mapped to `hostedView?.highlightStyle`.
    public override var highlightState: NSCollectionViewItem.HighlightState {
        get { return hostedView?.highlightStyle.state ?? .none }
        set { hostedView?.highlightStyle = newValue.style }
    }

    // MARK: Internal

    internal var menuTrackingCookie = 0

    // MARK: Private

    private var cachedLayoutAttributes: NSCollectionViewLayoutAttributes?
}

extension NSCollectionViewItem.HighlightState {
    fileprivate var style: ViewHighlightStyle {
        switch self {
        case .none:
            return .none
        case .forSelection:
            return .selection
        case .forDeselection:
            return .deselection
        case .asDropTarget:
            return .drop
        @unknown default:
            return .none
        }
    }
}

extension ViewHighlightStyle {
    fileprivate var state: NSCollectionViewItem.HighlightState {
        switch self {
        case .none:
            return .none
        case .selection, .contextMenu:
            return .forSelection
        case .deselection:
            return .forDeselection
        case .drop:
            return .asDropTarget
        }
    }
}
