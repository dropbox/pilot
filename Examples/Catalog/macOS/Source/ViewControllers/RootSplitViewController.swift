import Cocoa
import PilotUI

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
        sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarContainerViewController)
        sidebarItem.canCollapse = false

        contentListItem = NSSplitViewItem(contentListWithViewController: contentListContainerViewController)
        detailItem = NSSplitViewItem(viewController: detailViewController)
    }
    
    // MARK: Public
    
    public var sidebarViewController: NSViewController = EmptyViewController() {
        willSet { detachChildViewController(sidebarViewController) }
        didSet { attachChildViewController(sidebarViewController, to: sidebarContainerViewController) }
    }
    
    public var contentListViewController: NSViewController = EmptyViewController() {
        willSet { detachChildViewController(contentListViewController) }
        didSet { attachChildViewController(contentListViewController, to: contentListContainerViewController) }
    }
    
    public var detailViewController: NSViewController = EmptyViewController() {
        willSet { detachChildViewController(detailViewController) }
        didSet { attachChildViewController(detailViewController, to: detailContainerViewController) }
    }
    
    // MARK: NSViewController
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // `NSSplitViewController` has constraint warnings unless the items are set after the stack unwinds.
        DispatchQueue.main.async {
            self.splitViewItems = [self.sidebarItem, self.contentListItem, self.detailItem]
        }
    }
    
    // MARK: Private
    
    private var sidebarItem: NSSplitViewItem!
    private var contentListItem: NSSplitViewItem!
    private var detailItem: NSSplitViewItem!
    
    private let sidebarContainerViewController = EmptyViewController()
    private let contentListContainerViewController = EmptyViewController()
    private let detailContainerViewController = EmptyViewController()
    
    private func detachChildViewController(_ childViewController: NSViewController) {
        guard childViewController.parent != nil else { return }
        childViewController.view.removeFromSuperview()
        childViewController.removeFromParentViewController()
    }
    
    private func attachChildViewController(
        _ childViewController: NSViewController,
        to parentViewController: NSViewController
    ) {
        let parentView = parentViewController.view
        let childView = childViewController.view
        
        childView.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(childView)
        
        NSLayoutConstraint.activate([
            childView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            childView.topAnchor.constraint(equalTo: parentView.topAnchor),
            childView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
        ])
    }
}
