import AppKit
import Pilot
import PilotUI

public final class FileView: NSView, View {

    // MARK: View

    public init() {
        super.init(frame: .zero)
        loadSubviews()
    }

    public required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var viewModel: ViewModel? { return fileViewModel }

    public func bindToViewModel(_ viewModel: ViewModel) {
        let fileViewModel: FileViewModel = viewModel.typedViewModel()

        filenameLabel.stringValue = fileViewModel.filename
        iconView.image = NSWorkspace.shared.icon(forFile: fileViewModel.url.path)

        self.fileViewModel = fileViewModel
    }

    public func unbindFromViewModel() {
        fileViewModel = nil
    }

    public var highlightStyle: ViewHighlightStyle = .none {
        didSet {
            if selected || highlightStyle.highlighted {
                filenameLabel.font = NSFont.boldSystemFont(ofSize: 12)
            } else {
                filenameLabel.font = NSFont.systemFont(ofSize: 12)
            }
        }
    }

    public var selected: Bool = false {
        didSet {
            if selected || highlightStyle.highlighted {
                filenameLabel.font = NSFont.boldSystemFont(ofSize: 12)
            } else {
                filenameLabel.font = NSFont.systemFont(ofSize: 12)
            }
        }
    }

    public override func drawFocusRingMask() {
        iconView.frame.insetBy(dx: 1, dy: 1).fill()
        filenameLabel.frame.insetBy(dx: 1, dy: 1).fill()
    }

    public override func updateTrackingAreas() {
        let oldTrackingAreas = trackingAreas
        oldTrackingAreas.forEach { removeTrackingArea($0) }

        let trackingArea = NSTrackingArea(
            rect: visibleRect,
            options: [.activeInActiveApp, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil)
        addTrackingArea(trackingArea)
    }

    // MARK: NSResponder

    open override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        NSSound(named: NSSound.Name("thud"))?.play()
    }

    // MARK: Private

    private var fileViewModel: FileViewModel?
    private let filenameLabel = NSTextField()
    private let iconView = NSImageView()

    @objc
    private func handleDoubleClick() {
        fileViewModel?.handleDoubleClick()
    }

    private func loadSubviews() {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)
        filenameLabel.translatesAutoresizingMaskIntoConstraints = false
        filenameLabel.isEditable = false
        filenameLabel.backgroundColor = .clear
        filenameLabel.drawsBackground = false
        filenameLabel.isBezeled = false
        addSubview(filenameLabel)
        NSLayoutConstraint.activate([
            iconView.leftAnchor.constraint(equalTo: leftAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.heightAnchor.constraint(equalTo: heightAnchor),
            iconView.widthAnchor.constraint(equalTo: iconView.heightAnchor),
            filenameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            filenameLabel.leftAnchor.constraint(equalTo: iconView.rightAnchor),
            filenameLabel.rightAnchor.constraint(equalTo: rightAnchor),
            ])

        let doubleClick = NSClickGestureRecognizer(target: self, action: #selector(handleDoubleClick))
        doubleClick.numberOfClicksRequired = 2
        addGestureRecognizer(doubleClick)
    }
}
