import Pilot
import UIKit

/// `UICollectionReusableView` subclass which provies hosting for a given `View`.
/// - Note: Because cells are `UIView`s, the `View` must also be a `UIView` for hosting to be supported.
/// TODO:(wkiefer) Combine overlapping logic with `CollectionViewHostCell`.
internal final class CollectionViewHostReusableView: UICollectionReusableView {

    /// The hosted `View` instance.
    internal var hostedView: View? {
        willSet {
            if let view = hostedView as? UIView {
                // TODO:(wkiefer) Consider checking if view types match and not remove/readd but just rebind.
                // This also needs to unbind here (see TODO in the data source)
                view.removeFromSuperview()
            }
        }
        didSet {
            if let view = hostedView as? UIView {
                view.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
                view.frame = bounds
                addSubview(view)
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

    internal override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        cachedLayoutAttributes = layoutAttributes

        if let cvt = hostedView as? CollectionSupportingView {
            cvt.apply(layoutAttributes)
        }
    }

    // MARK: Private

    private var cachedLayoutAttributes: UICollectionViewLayoutAttributes?
}
