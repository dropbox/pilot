#if os(iOS)
import UIKit

public typealias PlatformCollectionView = UICollectionView
public typealias PlatformCollectionViewDelegate = UICollectionViewDelegate
public typealias PlatformCollectionViewLayout = UICollectionViewLayout
public typealias PlatformCollectionViewLayoutAttributes = UICollectionViewLayoutAttributes
public typealias PlatformCollectionViewLayoutInvalidationContext = UICollectionViewLayoutInvalidationContext
public typealias PlatformCollectionViewUpdateItem = UICollectionViewUpdateItem
public typealias PlatformEdgeInsets = UIEdgeInsets
public typealias PlatformFont = UIFont
public typealias PlatformLayoutPriority = UILayoutPriority
public typealias PlatformScrollView = UIScrollView
public typealias PlatformViewController = UIViewController
public typealias PlatformView = UIView

#elseif os(OSX)
import AppKit

public typealias PlatformCollectionView = NSCollectionView
public typealias PlatformCollectionViewDelegate = NSCollectionViewDelegate
public typealias PlatformCollectionViewLayout = NSCollectionViewLayout
public typealias PlatformCollectionViewLayoutAttributes = NSCollectionViewLayoutAttributes
public typealias PlatformCollectionViewLayoutInvalidationContext = NSCollectionViewLayoutInvalidationContext
public typealias PlatformCollectionViewUpdateItem = NSCollectionViewUpdateItem
public typealias PlatformEdgeInsets = NSEdgeInsets
public typealias PlatformFont = NSFont
public typealias PlatformLayoutPriority = Float
public typealias PlatformScrollView = NSScrollView
public typealias PlatformViewController = NSViewController
public typealias PlatformView = NSView
#endif
