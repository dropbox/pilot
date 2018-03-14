import Foundation
import Pilot

/// `UI/NSCollectionView`-specific additions to the `View` protocol
public protocol CollectionSupportingView: View {

    //
    // UI/NSCollectionViewCell-style methods. Invoked when the content view is the child of a view that supports these
    // methods.
    //

    func prepareForReuse()

#if os(iOS)
    func apply(_ layoutAttributes: UICollectionViewLayoutAttributes)
#elseif os(OSX)
    func apply(_ layoutAttributes: NSCollectionViewLayoutAttributes)
#endif

    func invalidateLayout()
}

/// Default empty implementations so views don't have to actually implement `CollectionView` methods unless desired.
extension CollectionSupportingView {
    public func prepareForReuse() {}

#if os(iOS)
    public func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {}
#elseif os(OSX)
    public func apply(_ layoutAttributes: NSCollectionViewLayoutAttributes) {}
#endif

    public func invalidateLayout() {
        guard let view = self as? PlatformView else { return }
        // NOTE(alan): This might not work on iOS or in future OS updates
        guard let collectionView = view.superview?.superview as? PlatformCollectionView else { return }

        // TODO(alan): Figure out how to only invalidate the single cell
    #if os(iOS)
        collectionView.collectionViewLayout.invalidateLayout()
    #elseif os(OSX)
        collectionView.collectionViewLayout?.invalidateLayout()
    #endif
    }
}
