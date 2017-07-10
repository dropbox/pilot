import AppKit

public final class EmptyViewController: NSViewController {
    
    // MARK: Init
    
    public override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError()
    }
    
    public convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    public convenience init(backgroundColor: NSColor) {
        self.init(nibName: nil, bundle: nil)
        backgroundView.backgroundColor = backgroundColor
    }
    
    // MARK: NSViewController
    
    public override func loadView() {
        view = backgroundView
    }
    
    // MARK: Private
    
    private let backgroundView = ColorView()
}
