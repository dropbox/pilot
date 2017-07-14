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
            viewBinder: ModelCollectionExampleViewBinder(),
            layout: layout,
            context: context)
        
    }
    
    // MARK: NSViewController
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        backgroundColor = .white
    }
}

// TODO:(wkiefer) Replace when Pilot has a block-based view binding provider.
fileprivate struct ModelCollectionExampleViewBinder: ViewBindingProvider {
    public func viewBinding(for viewModel: ViewModel, context: Context) -> ViewBinding {
        if viewModel is ModelCollectionExampleViewModel {
            return ViewBinding { return ExampleView() }
        }
        fatalError()
    }
}

