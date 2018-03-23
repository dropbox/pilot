import Pilot
import UIKit

/// `UICollectionViewCell` subclass which provies hosting for a given `View`.
/// - Note: Because cells are `UIView`s, the `View` must also be a `UIView` or `UIViewController`
/// for hosting to be supported.
internal final class CollectionViewHostCell: UICollectionViewCell {

    /// The hosted `View` instance.
    internal var hostedView: View? {
        willSet {
            if let view = hostedView as? UIView {
                if let newValue = newValue as? UIView, newValue == view {
                    // NOOP: The view is the same no need to remove.
                } else {
                    // TODO:(wkiefer) This also needs to unbind here (see TODO in the data source)
                    view.removeFromSuperview()
                }
            } else if let vc = hostedView as? UIViewController {
                if let newValue = newValue as? UIViewController, newValue == vc {
                    // NOOP: The view is the same, so no need to remove.
                } else {
                    // TODO:(wkiefer) This also needs to unbind here (see TODO in the data source)
                    vc.view.removeFromSuperview()
                }
            }
        }
        didSet {
            // Only add the view if it isn't already added (i.e. hit the noop case in `willSet`.
            if let view = hostedView as? UIView, view.superview != contentView {
                view.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
                view.frame = contentView.bounds
                contentView.addSubview(view)
            } else if let theVC = hostedView as? UIViewController, theVC.view.superview != contentView {
                theVC.view.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
                theVC.view.frame = contentView.bounds
                contentView.addSubview(theVC.view)
            }
            if let attribs = cachedLayoutAttributes, let cvt = hostedView as? CollectionSupportingView {
                cvt.apply(attribs)
            }
        }
    }

    // MARK: UIView

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.white
    }

    @available(*, unavailable, message: "Unsupported initializer.")
    required init?(coder aDecoder: NSCoder) {
        Log.fatal(message: "Unsupported initializer.")
    }

    // MARK: UICollectionReusableView

    internal override func prepareForReuse() {
        super.prepareForReuse()

        cachedLayoutAttributes = nil

        if let cvt = hostedView as? CollectionSupportingView {
            cvt.prepareForReuse()
        }
    }

    internal override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        cachedLayoutAttributes = layoutAttributes

        if let cvt = hostedView as? CollectionSupportingView {
            cvt.apply(layoutAttributes)
        }
    }

    // MARK: UICollectionViewCell

    override var isSelected: Bool {
        didSet {
            hostedView?.selected = isSelected
        }
    }

    override var isHighlighted: Bool {
        didSet {
            hostedView?.highlightStyle = isHighlighted ? .selection : .none
        }
    }

    // MARK: Private

    private var cachedLayoutAttributes: UICollectionViewLayoutAttributes?
}
