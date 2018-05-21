import AppKit
import Pilot

public final class OutlineViewModelDataSource: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    public init(
        model: NestedModelCollection,
        columns: [OutlineColumnConfig],
        context: Context
    ) {
        self.treeController = NestedModelCollectionTreeController(modelCollection: model)
        (self.modelBinders, self.viewBinders) = OutlineViewModelDataSource.extractBinders(columns)
        self.context = context
        super.init()
        self.collectionObserver = treeController.observe { [weak self] in
            self?.handleTreeControllerEvent($0)
        }
    }

    public weak var outlineView: NSOutlineView?
    public let context: Context

    // MARK: NSOutlineViewDataSource

    public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return treeController.countOfChildNodes(downcast(item) ?? [])
    }

    public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let indexPath = downcast(item) {
            return indexPath.appending(index) as NSIndexPath
        } else {
            return NSIndexPath(index: index)
        }
    }

    public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let indexPath = downcast(item) {
            return treeController.isExpandable(indexPath)
        }
        return false
    }

    // MARK: NSOutlineViewDelegate

    public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let indexPath = downcast(item) else { return nil }
        guard let identifier = tableColumn?.identifier else {
            Log.error(message: "Group rows not supported by OutlineViewModelDataSource")
            return nil
        }
        guard let viewBinder = viewBinders[identifier], let modelBinder = modelBinders[identifier] else {
            Log.error(message: "Missing binders for column \(identifier)")
            return nil
        }

        let model = treeController.modelAtIndexPath(indexPath)
        let viewModel = modelBinder.viewModel(for: model, context: context)

        var reuse: View?
        let type = viewBinder.viewTypeForViewModel(viewModel, context: context)
        let reuseId = NSUserInterfaceItemIdentifier(String(reflecting: type))
        if let view = outlineView.makeView(withIdentifier: reuseId, owner: self) as? View {
            reuse = view
        }

        let result = viewBinder.view(for: viewModel, context: context, reusing: reuse, layout: nil) as? NSView
        result?.identifier = reuseId
        return result
    }

    // MARK: Internal

    internal func outlineView(_ outlineView: NSOutlineView, menuForEvent event: NSEvent) -> NSMenu? {
        guard
            let location = outlineView.superview?.convert(event.locationInWindow, from: nil),
            let hitItem = outlineView.hitTest(location) as? View,
            let hitViewModel = hitItem.viewModel
        else {
            return nil
        }

        let actions = hitViewModel.secondaryActions(for: .secondaryClick)
        guard !actions.isEmpty else { return nil }
        return NSMenu.fromSecondaryActions(actions, action: #selector(didSelectContextMenuItem(_:)), target: self)
    }

    // MARK: Private

    private var collectionObserver: Observer?
    private var diffEngine = DiffEngine()
    private let treeController: NestedModelCollectionTreeController
    private let viewBinders: [NSUserInterfaceItemIdentifier: ViewBindingProvider]
    private let modelBinders: [NSUserInterfaceItemIdentifier: ViewModelBindingProvider]

    /// Responsible for taking a tree controller event and turnin it into NSOutlineView updates.
    private func handleTreeControllerEvent(_ event: NestedModelCollectionTreeController.Event) {
        guard let outlineView = outlineView else { return }

        // Group the updates based on index path of their parent, and filter out ones that are not visible.

        let removedByItem = Dictionary(grouping: event.removed, by: { $0.dropLast() as IndexPath })
            .filter({ $0.key == IndexPath() || outlineView.isItemExpanded($0.key as NSIndexPath) })
        let addedByItem = Dictionary(grouping: event.added, by: { $0.dropLast() as IndexPath })
            .filter({ $0.key == IndexPath() || outlineView.isItemExpanded($0.key as NSIndexPath) })
        let updatedItems = event.updated.map { $0 as IndexPath }
            .filter({ $0 == IndexPath() || outlineView.isItemExpanded($0.dropLast() as NSIndexPath) })

        guard !removedByItem.isEmpty || !addedByItem.isEmpty || !updatedItems.isEmpty else {
            return
        }

        // TODO:(danielh) Configuaration options for animations.
        let options = NSTableView.AnimationOptions.effectFade

        outlineView.beginUpdates()

        for (item, removed) in removedByItem {
            #if swift(>=4.1)
                let indexSet = IndexSet(removed.compactMap({ $0.last }))
            #else
                let indexSet = IndexSet(removed.flatMap({ $0.last }))
            #endif

            if item == IndexPath() {
                outlineView.removeItems(at: indexSet, inParent: nil, withAnimation: options)
            } else {
                outlineView.removeItems(at: indexSet, inParent: item as NSIndexPath, withAnimation: options)
            }
        }
        
        for (item, added) in addedByItem {
            #if swift(>=4.1)
                let indexSet = IndexSet(added.compactMap({ $0.last }))
            #else
                let indexSet = IndexSet(added.flatMap({ $0.last }))
            #endif
            if item == IndexPath() {
                outlineView.insertItems(at: indexSet, inParent: nil, withAnimation: options)
            } else {
                outlineView.insertItems(at: indexSet, inParent: item as NSIndexPath, withAnimation: options)
            }
        }

        for updated in updatedItems {
            outlineView.reloadItem(updated as NSIndexPath)
        }

        outlineView.endUpdates()
    }

    @objc
    private func didSelectContextMenuItem(_ menuItem: NSMenuItem) {
        guard let action = menuItem.representedAction else {
            Log.warning(message: "No action attached to secondary action menu item: \(menuItem)")
            return
        }
        action.send(from: context)
    }

    private func downcast(_ item: Any?) -> IndexPath? {
        if let item = item as? NSIndexPath {
            return item as IndexPath
        }
        if item != nil {
            Log.fatal(message: "Unexpected item returned from NSOutlineView \(String(reflecting: item))")
        }
        return nil
    }

    private typealias Identifier = NSUserInterfaceItemIdentifier
    private static func extractBinders(
        _ configs: [OutlineColumnConfig]
    ) -> ([Identifier: ViewModelBindingProvider], [Identifier: ViewBindingProvider]) {
        var modelBinders = [Identifier: ViewModelBindingProvider]()
        var viewBinders = [Identifier: ViewBindingProvider]()
        for config in configs {
            modelBinders[config.column.identifier] = config.modelBinder
            viewBinders[config.column.identifier] = config.viewBinder
        }
        return (modelBinders, viewBinders)
    }
}
