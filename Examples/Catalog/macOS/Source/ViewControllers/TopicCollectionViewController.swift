import Cocoa
import CatalogCore
import Pilot
import PilotUI

public final class TopicCollectionViewController: CollectionViewController {
    
    public static func make(with context: CatalogContext) -> TopicCollectionViewController {
        return TopicCollectionViewController(
            model: CommonModelCollections.makeTopics(),
            modelBinder: DefaultViewModelBindingProvider(),
            viewBinder: TopicViewBinder(),
            layout: CollectionViewListLayout(),
            context: context)
        
    }
}

// TODO:(wkiefer) Replace when Pilot has a block-based view binding provider.
fileprivate struct TopicViewBinder: ViewBindingProvider {
    public func viewBinding(for viewModel: ViewModel, context: Context) -> ViewBinding {
        if viewModel is TopicViewModel {
            return ViewBinding { return TopicView() }
        }
        fatalError()
    }
}
