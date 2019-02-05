import AppKit
import Foundation

public extension NSCollectionView {

    /// Sets the selection to the first item in the collection view,
    /// and optionally calls the delegate's selection method.
    func selectFirstItem(notifyingDelegate: Bool = false) {
        for section in 0..<numberOfSections {
            if numberOfItems(inSection: section) > 0 {
                setSingleSelection(0, section: section, notifyingDelegate: notifyingDelegate)
                return
            }
        }
    }

    /// Sets the selection to the last item in the collection view,
    /// and optionally calls the delegate's selection method.
    func selectLastItem(notifyingDelegate: Bool = false) {
        for section in (0..<numberOfSections).reversed() {
            let itemCount = numberOfItems(inSection: section)
            if itemCount > 0 {
                setSingleSelection(itemCount - 1, section: section, notifyingDelegate: notifyingDelegate)
                return
            }
        }
    }

    /// Sets the selection to item immediately following the current selection, and optionally calls the delegate's
    /// selection method. Assumes the current selection has one item.
    func selectNextItem(notifyingDelegate: Bool = false) {
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

        setSingleSelection(currentPath.item, section: currentPath.section, notifyingDelegate: notifyingDelegate)
    }

    /// Sets the selection to item immediately preceding the current selection, and optionally calls the delegate's
    /// selection method. Assumes the current selection has one item.
    func selectPreviousItem(notifyingDelegate: Bool = false) {
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

        setSingleSelection(currentPath.item, section: currentPath.section, notifyingDelegate: notifyingDelegate)
    }

    /// Scrolls to nearest edge taking into account the host scoll view's content inset.
    func verticallyScrollTo(itemAtIndexPath indexPath: IndexPath, animated: Bool = false) {
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

        if abs(topPoint.y - currentY) < abs(bottomPoint.y - currentY) {
            scrollBlock(topPoint)
        } else {
            scrollBlock(bottomPoint)
        }
    }

    private var hostScrollView: NSScrollView? {
        var next = superview
        while next != nil && next as? NSScrollView == nil {
            next = next?.superview
        }
        return next as? NSScrollView
    }

    private func setSingleSelection(_ item: Int, section: Int, notifyingDelegate: Bool) {
        let selectedIndexPath = IndexPath(forModelItem: item, inSection: section)
        selectionIndexPaths = [selectedIndexPath]
        verticallyScrollTo(itemAtIndexPath: selectedIndexPath)

        if notifyingDelegate {
            delegate?.collectionView?(self, didSelectItemsAt: selectionIndexPaths)
        }
    }
}
