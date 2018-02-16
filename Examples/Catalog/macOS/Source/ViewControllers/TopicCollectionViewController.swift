import Cocoa
import CatalogCore
import Pilot
import PilotUI

public final class TopicCollectionViewController: CollectionViewController {
    
    // MARK: Public
    
    public static func make(with context: CatalogContext) -> TopicCollectionViewController {
        let layout = CollectionViewListLayout()
        layout.defaultCellHeight = 24
        return TopicCollectionViewController(
            model: CommonModelCollections.makeTopics(),
            modelBinder: DefaultViewModelBindingProvider(),
            viewBinder: StaticViewBindingProvider(type: TopicView.self) ,
            layout: layout,
            context: context)
        
    }
}
