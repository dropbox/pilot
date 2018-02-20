import AppKit

public class ColorView: NSView {
    
    // MARK: Init
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
    }
    
    // MARK: Public
    
    public var backgroundColor: NSColor = .clear {
        didSet {
            needsDisplay = true
        }
    }
    
    // MARK: NSView
    
    public override var wantsUpdateLayer: Bool {
        return true
    }
    
    public override func updateLayer() {
        super.updateLayer()
        layer?.backgroundColor = backgroundColor.cgColor
    }
}
