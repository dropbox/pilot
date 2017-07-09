import Cocoa

public final class RootSplitViewController: NSSplitViewController {
    
    // MARK: Init
    
    public override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
    }
    
    // MARK: NSViewController
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let item1 = NSSplitViewItem(sidebarWithViewController: EmptyViewController())
        let item2 = NSSplitViewItem(contentListWithViewController: EmptyViewController())
        let item3 = NSSplitViewItem(viewController: EmptyViewController())
        
        // `NSSplitViewController` has constraint warnings unless the items are set after the stack unwinds.
        DispatchQueue.main.async {
            self.splitViewItems = [item1, item2, item3]
        }
    }
}

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
    
    // MARK: NSViewController
    
    public override func loadView() {
        view = ColorView()
    }
}
