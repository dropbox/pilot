import AppKit
import Pilot

/// `NSCollectionViewItem` subclass which provies hosting for a given `View`.
/// - Note: Because items are `NSView`s, the `View` must also be a `NSView` for hosting to be supported.
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
            }
        }
        didSet {
            // Only add the view if it isn't already added (i.e. hit the noop case in `willSet`.)
            if let view = hostedView as? NSView, newValue == view {
                // NOOP: The view is the same, so no need to add.
            } else {
                view.addSubview(theView)
                theView.translatesAutoresizingMaskIntoConstraints = false
                theView.constrain(edgesEqualToView: view)
            }
            hostedView?.selected = isSelected
            if let attribs = cachedLayoutAttributes, let cvt = hostedView as? CollectionSupportingView {
                cvt.apply(attribs)
            }
            menuTrackingCookie += 1
        }
    }

    public var highlightStyle: ViewHighlightStyle {
        get {
            return (hostedView?.highlightStyle ?? .none)!
        }
        set {
            hostedView?.highlightStyle = newValue
        }
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

    public override var isSelected: Bool {
        didSet {
            hostedView?.selected = isSelected
        }
    }

    public override var highlightState: NSCollectionViewItem.HighlightState {
        didSet {
            hostedView?.highlightStyle = highlightState.style
        }
    }

    // MARK: Internal

    internal var menuTrackingCookie = 0

    // MARK: Private

    fileprivate var cachedLayoutAttributes: NSCollectionViewLayoutAttributes?
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
        }
    }
}
