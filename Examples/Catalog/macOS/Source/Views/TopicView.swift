import AppKit
import CatalogCore
import Pilot

public final class TopicView: NSView, View {
    
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
        
        selectionView.selectionHighlightStyle = .sourceList
        
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(selectionView)
        addSubview(textField, positioned: .above, relativeTo: selectionView)
        
        NSLayoutConstraint.activate([
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            selectionView.topAnchor.constraint(equalTo: topAnchor),
            selectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            selectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            selectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    
    // MARK: View
    
    public func bindToViewModel(_ viewModel: ViewModel) {
        let tvm: TopicViewModel = viewModel.typedViewModel()
        topicViewModel = tvm
        textField.stringValue = tvm.title
    }
    
    public func unbindFromViewModel() {
        topicViewModel = nil
        textField.stringValue = ""
    }
    
    public var viewModel: ViewModel? {
        return topicViewModel
    }
    
    public var selected: Bool {
        set {
            selectionView.isSelected = newValue
        }
        get {
            return selectionView.isSelected
        }
    }
    
    // MARK: Private
    
    private var topicViewModel: TopicViewModel?
    private let textField = NSTextField()
    private let selectionView = NSTableRowView()
}
