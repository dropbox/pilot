import Cocoa
import CatalogCore
import Pilot
import PilotUI

public final class ModelCollectionExampleCollectionViewController: CollectionViewController {
    
    // MARK: Public
    
    public static func make(with context: CatalogContext) -> ModelCollectionExampleCollectionViewController {
        let layout = CollectionViewListLayout()
        return ModelCollectionExampleCollectionViewController(
            model: CommonModelCollections.makeModelCollectionExamples(),
            modelBinder: DefaultViewModelBindingProvider(),
            viewBinder: StaticViewBindingProvider(type: ExampleView.self),
            layout: layout,
            context: context)
        
    }
    
    // MARK: NSViewController
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        backgroundColor = .white
    }
}
