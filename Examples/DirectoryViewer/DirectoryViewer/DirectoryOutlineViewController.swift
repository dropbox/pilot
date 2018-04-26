import Pilot
import PilotUI

public final class DirectoryOutlineViewController: OutlineViewController {
    init(url: URL, context: Context) {
        super.init(
            model: DirectoryModelCollection(url: url),
            modelBinder: DirectoryModelBinder(),
            viewBinder: StaticViewBindingProvider(type: FileView.self),
            context: context)
    }
}
