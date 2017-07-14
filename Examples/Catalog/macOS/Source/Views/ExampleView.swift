import AppKit
import CatalogCore
import Pilot

public final class ExampleView: ColorView, View {
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    public convenience init() {
        self.init(frame: .zero)
        commonInit()
    }
    
    private func commonInit() {
        textField.isEditable = false
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.textColor = NSColor.labelColor
        textField.backgroundColor = .clear
        textField.drawsBackground = true
        textField.isBordered = false

        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)
        
        NSLayoutConstraint.activate([
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        ])
    }
    
    // MARK: View
    
    public func bindToViewModel(_ viewModel: ViewModel) {
        guard let evm: ExampleViewModel = viewModel as? ExampleViewModel else { fatalError() }
        exampleViewModel = evm
        textField.stringValue = evm.exampleTitle
    }
    
    public func unbindFromViewModel() {
        exampleViewModel = nil
        textField.stringValue = ""
    }
    
    public var viewModel: ViewModel? {
        return exampleViewModel
    }
    
    public var selected: Bool = false {
        didSet {
            backgroundColor = selected ? NSColor.selectedControlColor : NSColor.white
        }
    }
    
    // MARK: Private
    
    private var exampleViewModel: ExampleViewModel?
    private let textField = NSTextField()
}

