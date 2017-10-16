import Foundation
import Pilot

/// Protocol extending `NSCollectionViewDelegate` with a few missing callbacks around item clicking and key events.
@objc
public protocol CollectionViewDelegate: NSCollectionViewDelegate {

    /// Invoked when a keyboard key is pressed - clients may check the selection state to determine if an action should
    /// be taken. If true is returned from this function event is consumed.
    @objc optional func collectionViewDidReceiveKeyEvent(
        _ collectionView: NSCollectionView,
        key: EventKeyCode,
        modifiers: NSEvent.ModifierFlags
    ) -> Bool

    /// Invoked when a specific index path is clicked upon - this allows the client to handle clicks without breaking
    /// the typical `NSCollectionView` selection state (otherwise, underlying item views do not get all mouse events).
    @objc optional func collectionView(_ collectionView: NSCollectionView, didClickIndexPath indexPath: IndexPath)

    /// Invoked when a specific index path is right-clicked upon.
    @objc optional func collectionView(_ collectionView: NSCollectionView, menuForIndexPath: IndexPath) -> NSMenu?

    /// Invoked when NSDraggingSource method of parallel signature is called.
    ///
    /// This is provided since NSCV delegate method has a corresponding function for -begin and -end functions in
    /// NSDraggingSource, but no equivelant for -movedTo.
    @objc optional func collectionView(_ collectionView: NSCollectionView, session: NSDraggingSession, movedTo: NSPoint)

    /// Invoked when an arrow key goes off the end of a collection view. Delegate may respond by changing the responder
    /// focus.
    @objc optional func collectionViewShouldLoseFocusFromArrowKey(_ collectionView: NSCollectionView, key: EventKeyCode)
}

/// Internal `NSCollectionView` which provides additional responder events.
public final class CollectionView: NSCollectionView {

    // MARK: Public

    /// If `true`, then the first visible item will automatically be selected when the collection view gets focus.
    public var autoSelectItemOnFocus: Bool = false

    /// If `true`, then the collection view will not send key down events to the superview disabling selection.
    public var keyboardSelectionDisabled: Bool = false

    /// If `true` then the collection view will accept first responder. Set this to false when this behaviour is not
    /// desired for example when the collection view is empty or focus should move to a different part of the UI.
    public var shouldAcceptFirstResponder: Bool = true

    // MARK: NSResponder

    public override func keyDown(with event: NSEvent) {
        let handled = internalDelegate?.collectionViewDidReceiveKeyEvent?(
            self,
            key: event.eventKeyCode,
            modifiers: event.eventKeyModifierFlags.modifierFlags)
        guard handled != true else { return }
        switch event.eventKeyCode {
        case .upArrow, .downArrow:
            let oldSelectionIndexPaths = selectionIndexPaths

            // TODO:(danielh) investigate whether this should have an else that forwards events while skipping super's
            // selection behavior.
            if !keyboardSelectionDisabled {
                super.keyDown(with: event)
            }

            // Determine if the key down event changed selection.
            var selectionDidChange = false
            if oldSelectionIndexPaths != selectionIndexPaths {
                selectionDidChange = true
            }

            if !selectionDidChange, let code = EventKeyCode(rawValue: event.keyCode) {
                internalDelegate?.collectionViewShouldLoseFocusFromArrowKey?(self, key: code)
            }
        default:
            super.keyDown(with: event)
        }
    }

    public override func mouseDown(with event: NSEvent) {
        guard !event.modifierFlags.contains(.control) else {
            return self.rightMouseDown(with: event)
        }

        super.mouseDown(with: event)

        // Cancel any previous calls to `autoSelectFirstVisible` that were issued as a result of the mouse click
        // first making this view the first responder.
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(autoSelectFirstItem), object: nil)

        let point = convert(event.locationInWindow, from: nil)
        if let indexPath = indexPathForItem(at: point) {
            internalDelegate?.collectionView?(self, didClickIndexPath: indexPath)
        }
    }

    public override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        if let indexPath = indexPathForItem(at: point) {
            return internalDelegate?.collectionView?(self, menuForIndexPath: indexPath)
        }
        return nil
    }

    public override var acceptsFirstResponder: Bool {
        return shouldAcceptFirstResponder
    }

    public override func becomeFirstResponder() -> Bool {
        let ret = super.becomeFirstResponder()

        // Delay this call to allow for `mouseDown` to come through. It should only be called for non-mouse focus
        // changes.
        if ret && autoSelectItemOnFocus {
            perform(#selector(autoSelectFirstItem), with: nil, afterDelay: 0.0)
        }
        return ret
    }

    public func validCell(atIndexPath indexPath: IndexPath) -> Bool {
        guard (indexPath as NSIndexPath).section >= 0 && (indexPath as NSIndexPath).item >= 0 else { return false }
        guard (indexPath as NSIndexPath).section < numberOfSections else { return false }
        guard (indexPath as NSIndexPath).item < numberOfItems(inSection: (indexPath as NSIndexPath).section) else { return false }
        return true
    }

    // MARK: NSDraggingSource

    public override func draggingSession(_ session: NSDraggingSession, movedTo screenPoint: NSPoint) {
        super.draggingSession(session, movedTo: screenPoint)
        internalDelegate?.collectionView?(self, session: session, movedTo: screenPoint)
    }

    // MARK: Private

    fileprivate var internalDelegate: CollectionViewDelegate? {
        return delegate as? CollectionViewDelegate
    }

    @objc
    fileprivate func autoSelectFirstItem() {
        if autoSelectItemOnFocus && selectionIndexes.count == 0 {
            selectFirstItem()
        }
    }
}
