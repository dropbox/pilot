import Foundation
import Pilot
import PilotUI

public final class DirectoryCollectionViewController: CollectionViewController {

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
