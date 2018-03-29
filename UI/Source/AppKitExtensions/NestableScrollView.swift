import AppKit

open class NestableScrollView : NSScrollView {
    open var scrollEnabled: Bool = true

    // MARK: NSScrollView

    open override func scrollWheel(with theEvent: NSEvent) {
        guard scrollEnabled else {
            enclosingScrollView?.scrollWheel(with: theEvent)
            return
        }

        var selfShouldScroll = true
        if let enclosingScrollView = enclosingScrollView, let documentView = documentView {
            let documentVisibleRect = contentView.documentVisibleRect
            let scrolledPastTop = documentVisibleRect.minY < documentView.frame.minY - contentInsets.top
            let scrolledPastBottom = documentVisibleRect.maxY > documentView.frame.maxY + contentInsets.bottom

            if scrolledPastBottom && theEvent.scrollingDeltaY < 0.0 {
                enclosingScrollView.scrollWheel(with: theEvent)
                selfShouldScroll = false
            } else if scrolledPastTop && theEvent.scrollingDeltaY > 0.0 {
                enclosingScrollView.scrollWheel(with: theEvent)
                selfShouldScroll = false
            }
        }

        if selfShouldScroll {
            super.scrollWheel(with: theEvent)
        }
    }

    open override func flashScrollers() {
        if scrollEnabled {
            super.flashScrollers()
        }
    }
}
