import AppKit

/// Like pubs, tea, politeness, al-u-min-i-um, bangers and mash, Hogwartz, and all other great things from
/// Alpha America, this view provides an elequant and refined take on the classic `NSVisualEffectView`. It supports
/// a non-gray tinted version of a visual effect view suitable for white-on-white display.
public final class RobMasonVisualEffectView: NSVisualEffectView {

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
        material = .light
        blendingMode = .withinWindow
        updateVisualEffectBackgroundColor()
    }

    deinit {
        unregisterForWindowNotifications()
    }

    // MARK: NSView

    public override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateVisualEffectBackgroundColor()
    }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        sublayerObserver = layer?.observe(\CALayer.sublayers, changeHandler: { [weak self] (_, _) in
            self?.updateVisualEffectBackgroundColor()
        })

        if let window = window {
            registerForWindowNotifications(window)
            mainWindowDidChange()

            state = .inactive
            DispatchQueue.main.async {
                self.updateVisualEffectBackgroundColor()
                self.state = .active
                self.state = .followsWindowActiveState
            }
            perform(#selector(fadeOutUnderlayView), with: nil, afterDelay: 0.2)
        }
    }

    public override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)

        updateVisualEffectBackgroundColor()
        unregisterForWindowNotifications()

        if newWindow != nil {
            addUnderlayView()
        }
    }

    // MARK: Private

    private var underlayView: NSView? {
        didSet {
            if let oldView = oldValue {
                oldView.removeFromSuperview()
            }
            if let underlayView = underlayView {
                addSubview(underlayView, positioned: .below, relativeTo: nil)
                underlayView.translatesAutoresizingMaskIntoConstraints = false
                underlayView.constrain(edgesEqualToView: self)
            }
        }
    }

    private weak var observedWindow: NSWindow?

    private func registerForWindowNotifications(_ window: NSWindow) {
        unregisterForWindowNotifications()

        let nc = NotificationCenter.default
        nc.addObserver(
            self,
            selector: #selector(mainWindowDidChange),
            name: NSWindow.didBecomeMainNotification,
            object: window)
        nc.addObserver(
            self,
            selector: #selector(mainWindowDidChange),
            name: NSWindow.didResignMainNotification,
            object: window)

        observedWindow = window
    }

    private func unregisterForWindowNotifications() {
        guard let window = observedWindow else { return }

        let nc = NotificationCenter.default
        nc.removeObserver(self, name: NSWindow.didBecomeMainNotification, object: window)
        nc.removeObserver(self, name: NSWindow.didResignMainNotification, object: window)

        observedWindow = nil
    }

    @objc
    private func mainWindowDidChange() {
        let isMain = window?.isMainWindow ?? false
        if isMain {
            fadeOutUnderlayView()
        } else {
            fadeInUnderlayView()
        }
    }

    private func addUnderlayView() {
        if underlayView == nil {
            underlayView = ColorView(backgroundColor: .white)
        }
    }

    @objc
    private func fadeInUnderlayView() {
        // Don't let existing fade outs clear the view.
        onFadeOutCompletion = { }

        // Add if necessary.
        addUnderlayView()

        // Animate.
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            underlayView?.animator().alphaValue = 1.0
        }, completionHandler: nil)
    }

    @objc
    private func fadeOutUnderlayView() {
        onFadeOutCompletion = { [weak self] in self?.underlayView = nil }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            underlayView?.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            self?.onFadeOutCompletion()
        })
    }

    private var onFadeOutCompletion: () -> Void = {}

    private let tintedColor = NSColor(white: 1.0, alpha: 0.8).cgColor

    private func updateVisualEffectBackgroundColor() {
        if let sublayers = layer?.sublayers {
            for sublayer in sublayers where sublayer.name == "kCUIVariantMacLightMaterial" {
                if let sublayers2 = sublayer.sublayers {
                    for sublayer2 in sublayers2 {
                        if let sublayers3 = sublayer2.sublayers {
                            for sublayer3 in sublayers3 {
                                sublayer3.backgroundColor = tintedColor
                            }
                        }
                    }
                }
            }
        }
    }

    private var sublayerObserver: Any?
}
