import Pilot
import UIKit

public protocol NestedModelCollectionViewViewModel: ViewModel {
    var dataSource: UICollectionViewDataSource { get }
    var layout: UICollectionViewLayout { get }
    /// Closure that gets called when view model is bound to the view, for configuring UICollectionView properties other
    /// than the dataSource and collectionViewLayout.
    var configureCollectionView: (UICollectionView) -> Void { get }
    /// Closure that gets called once per binding when the collection view's layoutSubviews() is called with a nonEmpty
    /// bounds.
    var collectionViewDidLayout: (UICollectionView) -> Void { get }
}

/// `UICollectionView` subclass expected to bind to a view model that conforms to `NestedCollectionViewModel`.
public final class NestedModelCollectionView: UICollectionView, View {


    // MARK: Init

    public init() {
        super.init(frame: .zero, collectionViewLayout: UICollectionViewLayout())
    }

    @available(*, unavailable, message: "init(coder:) has not been implemented")
    required public init?(coder aDecoder: NSCoder) {
        Log.fatal(message: "init(coder:) has not been implemented")
    }

    // MARK: CollectionView

    public func prepareForReuse() {
        unbindFromViewModel()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if !alreadyCalledLayout && !bounds.isEmpty {
            alreadyCalledLayout = true
            collectionViewModel?.collectionViewDidLayout(self)
        }
    }

    // MARK: View

    public var viewModel: ViewModel? {
        return collectionViewModel
    }

    public func bindToViewModel(_ viewModel: ViewModel) {
        guard let vm = viewModel as? NestedModelCollectionViewViewModel else {
            assertionFailureWithLog(message: "CollectionView received unsuppored view model: \(type(of: viewModel))")
            return
        }
        alreadyCalledLayout = false
        collectionViewModel = vm
        dataSource = vm.dataSource

        // Ensure the data source has a weak ref back to the proper collection view.
        if let modelDataSource = dataSource as? CollectionViewModelDataSource {
            modelDataSource.collectionView = self
        }

        collectionViewLayout = vm.layout
        reloadData()
        vm.configureCollectionView(self)
    }

    public func unbindFromViewModel() {
        if let modelDataSource = dataSource as? CollectionViewModelDataSource {
            modelDataSource.collectionView = nil
        }
        dataSource = nil
        delegate = nil
        collectionViewLayout = UICollectionViewLayout()
        collectionViewModel = nil
    }

    // MARK: Private

    fileprivate var collectionViewModel: NestedModelCollectionViewViewModel?
    fileprivate var alreadyCalledLayout = false
}
