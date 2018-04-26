import AppKit
import Pilot

/// Configuration struct describing a table column with corresponding MVVM binding support. You can retain a reference
/// to the column in order to do any dynamic hiding/resizing operations.
public struct OutlineColumnConfig {
    public init(
        column: NSTableColumn,
        modelBinder: ViewModelBindingProvider,
        viewBinder: ViewBindingProvider,
        isOutlineColumn: Bool = false
    ) {
        self.column = column
        self.modelBinder = modelBinder
        self.viewBinder = viewBinder
        self.isOutlineColumn = isOutlineColumn
    }
    var isOutlineColumn: Bool
    var column: NSTableColumn
    var modelBinder: ViewModelBindingProvider
    var viewBinder: ViewBindingProvider
}

/// View Controller implementation to show a given `ModelCollection` in an outline view.
///
/// As with CollectionViewController, subclassing should typically be only for app-specific view controlle behavior (not
/// cell configuration).
open class OutlineViewController: ModelCollectionViewController, NSMenuDelegate {

    /// Multi-column outline view.
    public init(
        model: ModelCollection,
        columns: [OutlineColumnConfig],
        context: Context
    ) {
        let context = context.newScope()
        self.dataSource = OutlineViewModelDataSource(
            model: model.asNested(),
            columns: columns,
            context: context)
        self.columnConfigs = columns
        self.outlineView = OutlineView()
        super.init(model: model, context: context)
    }

    /// Shortcut for creating a single full-width column outline view (with expansion enabled).
    public init(
        model: ModelCollection,
        modelBinder: ViewModelBindingProvider,
        viewBinder: ViewBindingProvider,
        context: Context
    ) {
        let context = context.newScope()
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("com.pilot.outlineviewcontroller.column"))
        column.resizingMask = .autoresizingMask
        let columnConfig = OutlineColumnConfig(
            column: column,
            modelBinder: modelBinder,
            viewBinder: viewBinder,
            isOutlineColumn: true)
        self.dataSource = OutlineViewModelDataSource(
            model: model.asNested(),
            columns: [columnConfig],
            context: context)
        self.columnConfigs = [columnConfig]
        self.outlineView = OutlineView()
        super.init(model: model, context: context)
    }

    // MARK: Public

    public let outlineView: NSOutlineView
    public let dataSource: OutlineViewModelDataSource

    // MARK: ModelCollectionViewContoller

    public final override func makeScrollView() -> NSScrollView {
        // TODO:(danielh) Investigate why NSOutlineView doesn't work when hosted in a NestableScrollView.
        return NSScrollView()
    }

    public final override func makeDocumentView() -> NSView {
        outlineView.wantsLayer = true
        outlineView.layerContentsRedrawPolicy = .onSetNeedsDisplay
        outlineView.autoresizingMask = [.width, .height]
        return outlineView
    }

    // MARK: NSViewController

    open override func viewDidLoad() {
        super.viewDidLoad()
        // TODO:(danielh) support header view / configuration of column headers
        outlineView.headerView = nil
        for config in columnConfigs {
            outlineView.addTableColumn(config.column)
            if config.isOutlineColumn {
                outlineView.outlineTableColumn = config.column
            }
        }
        if outlineView.outlineTableColumn == nil {
            // https://twitter.com/warrenm/status/970729145457025024
            Log.warning(
                message: "OutlineViewController created without an outlineTableColumn, this will disable expanding.")
        }
        outlineView.autoresizesOutlineColumn = true
        outlineView.delegate = dataSource
        outlineView.dataSource = dataSource
        scrollView.scrollerStyle = .overlay
        dataSource.outlineView = outlineView
    }

    private let columnConfigs: [OutlineColumnConfig]
}

private final class OutlineView: NSOutlineView {
    override func menu(for event: NSEvent) -> NSMenu? {
        return (delegate as? OutlineViewModelDataSource)?.outlineView(self, menuForEvent: event)
    }
}
