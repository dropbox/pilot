import Foundation
import Pilot
import PilotUI

public final class DirectoryViewController: CollectionViewController {

    init(url: URL, context: Context) {
        self.flowLayout = NSCollectionViewFlowLayout()
        super.init(
            model: DirectoryModelCollection(url: url),
            modelBinder: DirectoryModelBinder(),
            viewBinder: StaticViewBindingProvider(type: FileView.self),
            layout: flowLayout,
            context: context)
    }

    // MARK: NSViewController

    public override func viewDidLayout() {
        super.viewDidLayout()
        flowLayout.itemSize = CGSize(width: view.bounds.width, height: 44)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.allowsMultipleSelection = true
    }

    public override func displayForNoContentState() -> EmptyCollectionDisplay {
        return .text("Nothing to see here…", NSFont.boldSystemFont(ofSize: 14), NSColor.disabledControlTextColor)
    }

    // MARK: Private

    private let flowLayout: NSCollectionViewFlowLayout
}

private struct DirectoryModelBinder: ViewModelBindingProvider {
    func viewModel(for model: Model, context: Context) -> ViewModel {
        return FileViewModel(model: model, context: context)
    }

    func selectionViewModel(for models: [Model], context: Context) -> SelectionViewModel? {
        let files: [FileViewModel] = models.flatMap({ ($0 as? File)?.viewModelWithContext(context) as? FileViewModel })
        return FileSelectionViewModel(viewModels: files, context: context)
    }
}

private struct FileSelectionViewModel: SelectionViewModel {
    init(viewModels: [ViewModel], context: Context) {
        self.files = viewModels.map { $0.typedViewModel() }
        self.context = context
    }

    var files: [FileViewModel]
    var context: Context

    // MARK: ViewModelType

    func canHandleUserEvent(_ event: ViewModelUserEvent) -> Bool {
        for file in files {
            if !file.canHandleUserEvent(event) {
                return false
            }
        }
        return true
    }

    func handleUserEvent(_ event: ViewModelUserEvent) {
        for file in files {
            file.handleUserEvent(event)
        }
    }

    func secondaryActions(for event: ViewModelUserEvent) -> [SecondaryAction] {
        let names = files.map({ $0.filename }).joined(separator: ",")
        let action = OpenFilesAction(urls: files.map({ $0.url }))
        let title = files.count == 1 ? "Open" : "Open \(files.count) files"
        let open = SecondaryActionInfo(metadata: SecondaryActionInfo.Metadata.init(title: title), action: action)
        return [.info("Selected: \(names)"), .action(open)]
    }
}
