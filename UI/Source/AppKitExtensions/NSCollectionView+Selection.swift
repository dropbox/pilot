import AppKit
import Foundation

public extension NSCollectionView {

    /// Sets the selection to the first item in the collection view.
    public func selectFirstItem() {
        for section in 0..<numberOfSections {
            if numberOfItems(inSection: section) > 0 {
                setSingleSelection(0, section: section)
                return
            }
        }
    }

    /// Sets the selection to the last item in the collection view.
    public func selectLastItem() {
        for section in (0..<numberOfSections).reversed() {
            let itemCount = numberOfItems(inSection: section)
            if itemCount > 0 {
                setSingleSelection(itemCount - 1, section: section)
                return
            }
        }
    }

    /// Sets the selection to item immediately following the current selection.
    /// Assumes the current selection has one item.
    public func selectNextItem() {
        let sectionCount = numberOfSections
        if sectionCount == 0 { return }

        let currentSelection = selectionIndexPaths
        guard let currentSelectionPath = currentSelection.first else {
            selectFirstItem()
            return
        }

        var currentPath = (
            item: (currentSelectionPath as NSIndexPath).item,
            section: (currentSelectionPath as NSIndexPath).section)

        currentPath.item += 1

        while currentPath.item >= numberOfItems(inSection: currentPath.section) {
            currentPath.item = 0
            currentPath.section += 1
            if currentPath.section >= sectionCount {
                currentPath.section = 0
            }
        }

        setSingleSelection(currentPath.item, section: currentPath.section)
    }

    /// Sets the selection to item immediately preceding the current selection.
    /// Assumes the current selection has one item.
    public func selectPreviousItem() {
        let sectionCount = numberOfSections
        if sectionCount == 0 { return }

        let currentSelection = selectionIndexPaths
        guard let currentSelectionPath = currentSelection.first else {
            selectLastItem()
            return
        }

        var currentPath = (
            item: (currentSelectionPath as NSIndexPath).item,
            section: (currentSelectionPath as NSIndexPath).section)

        currentPath.item -= 1

        while currentPath.item < 0 {
            currentPath.section -= 1
            if currentPath.section < 0 {
                currentPath.section = sectionCount - 1
            }
            currentPath.item = numberOfItems(inSection: currentPath.section) - 1
        }

        setSingleSelection(currentPath.item, section: currentPath.section)
    }

    /// Scrolls to nearest edge taking into account the host scoll view's content inset.
    public func verticallyScrollTo(itemAtIndexPath indexPath: IndexPath, animated: Bool = false) {
        guard
            let hostScrollView = hostScrollView,
            let layoutAttributes = layoutAttributesForItem(at: indexPath as IndexPath)
        else {
            scrollToItems(at: Set([indexPath]) as Set<IndexPath>, scrollPosition: NSCollectionView.ScrollPosition.centeredVertically)
            return
        }
        let currentY = hostScrollView.documentVisibleRect.origin.y
        let topInset = hostScrollView.contentInsets.top
        let itemFrame = layoutAttributes.frame
        let scrollHeight = hostScrollView.bounds.height
        let alreadyVisible = currentY + topInset < itemFrame.minY && currentY + topInset + scrollHeight > itemFrame.maxY
        guard !alreadyVisible else {
            return
        }
        let topPoint = NSPoint(x: itemFrame.origin.x, y: itemFrame.origin.y - topInset)
        let bottomPoint = NSPoint(
            x: itemFrame.origin.x,
            y: max(-topInset, itemFrame.maxY - hostScrollView.bounds.height))

        let scrollBlock: (NSPoint) -> Void = { point in
            if animated {
                hostScrollView.contentView.animator().setBoundsOrigin(point)
                hostScrollView.reflectScrolledClipView(hostScrollView.contentView)
            } else {
                self.scroll(point)
            }
        }

        if fabs(topPoint.y - currentY) < fabs(bottomPoint.y - currentY) {
            scrollBlock(topPoint)
        } else {
            scrollBlock(bottomPoint)
        }
    }

    fileprivate var hostScrollView: NSScrollView? {
        var next = superview
        while next != nil && next as? NSScrollView == nil {
            next = next?.superview
        }
        return next as? NSScrollView
    }

    fileprivate func setSingleSelection(_ item: Int, section: Int) {
        let selectedIndexPath = IndexPath(forModelItem: item, inSection: section)
        selectionIndexPaths = [selectedIndexPath]
        verticallyScrollTo(itemAtIndexPath: selectedIndexPath)
    }
}
