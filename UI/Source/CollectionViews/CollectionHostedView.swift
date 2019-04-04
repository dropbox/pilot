#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

import Foundation
import Pilot

/// `UICollectionView`-specific additions to the `View` protocol
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
}

/// Default empty implementations so views don't have to actually implement `CollectionView` methods unless desired.
extension CollectionSupportingView {
    public func prepareForReuse() {}

#if os(iOS)
    public func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {}
#elseif os(OSX)
    public func apply(_ layoutAttributes: NSCollectionViewLayoutAttributes) {}
#endif
}
