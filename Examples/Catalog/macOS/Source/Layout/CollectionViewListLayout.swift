import AppKit
import Pilot

/// `NSCollectionViewFlowLayout` which presents items as a full-width list. This class handles auto-invalidating itself
/// when the bounds change in a way that requires a new layout pass.
public class CollectionViewListLayout: NSCollectionViewFlowLayout {
    
    // MARK: Init
    
    public override init() {
        super.init()
        
        self.minimumInteritemSpacing = 0
        self.minimumLineSpacing = 0
        self.scrollDirection = .vertical
        self.sectionInset = NSEdgeInsets()
    }
    
    @available(*, unavailable, message: "Unsupported initializer")
    public required init?(coder aDecoder: NSCoder) {
        fatalError("Unsupported initializer")
    }
    
    // MARK: Public
    
    /// Determines if the flow layout should use cell autoresizing (via `estimatedItemSize`). If `true`, then
    /// `estimatedItemSize` is updated alongside `defaultCellHeight`.
    public var usesAutosizingCells: Bool = false {
        didSet {
            if usesAutosizingCells {
                updateMetricsForBounds(lastBounds)
            } else {
                estimatedItemSize = CGSize.zero
            }
        }
    }
    
    /// Determines the default cell height to use in the layout.
    public var defaultCellHeight: CGFloat = 56 {
        didSet {
            updateMetricsForBounds(lastBounds)
        }
    }
    
    /// Invoked when the collection view content size has changed.
    public var collectionViewContentSizeDidChange: () -> Void = {}
    
    // MARK: UICollectionViewLayout
    
    open override var sectionInset: NSEdgeInsets {
        didSet {
            updateMetricsForBounds(lastBounds)
        }
    }
    
    open override func prepare() {
        if lastBounds.isEmpty {
            lastBounds = collectionView?.bounds ?? CGRect()
            updateMetricsForBounds(lastBounds)
        }
        
        super.prepare()
        
        // Let the stack unwind so the parent layout can finish its work to calculate collectionViewContentSize.
        Async.onMain { self.collectionViewContentSizeDidChange() }
    }
    
    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        let oldBounds = lastBounds
        lastBounds = newBounds
        
        if !oldBounds.width.isEqual(to: newBounds.width) {
            updateMetricsForBounds(newBounds)
            return true
        }
        return false
    }
    
    // MARK: Private
    
    private var lastBounds: CGRect = CGRect()
    
    private func updateMetricsForBounds(_ bounds: CGRect) {
        let inset = sectionInset
        var width = bounds.size.width - inset.left - inset.right
        
        // Sometimes during bootstrap, the bounds is not yet set, so keep the default pre-existing width rather than
        // attempting to set to zero.
        if width < 1 {
            width = itemSize.width
        }
        
        itemSize = CGSize(width: width, height: defaultCellHeight)
        
        if usesAutosizingCells {
            estimatedItemSize = itemSize
        }
        
        // TODO:(wkiefer) This shouldn't really be needed - setting itemSize should invalidate.
        self.invalidateLayout()
    }
}
