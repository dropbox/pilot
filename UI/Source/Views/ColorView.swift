import Foundation

/// Provides a layer-backed `NSView` that supports a single background color.
@IBDesignable
internal class ColorView: NSView {

    // MARK: Init

    internal override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
    }

    internal required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
    }

    internal convenience init(backgroundColor: NSColor) {
        self.init(frame: .zero)
        self.backgroundColor = backgroundColor
    }

    // MARK: Public

    @IBInspectable
    internal var backgroundColor: NSColor = .clear {
        didSet {
            needsDisplay = true
        }
    }

    // MARK: NSView

    internal override var wantsUpdateLayer: Bool {
        return true
    }

    internal override func updateLayer() {
        layer?.backgroundColor = backgroundColor.cgColor
    }
}

