import UIKit
import Pilot
import PilotUI

public final class MediaSearchViewController: CollectionViewController, UISearchBarDelegate, UICollectionViewDelegateFlowLayout {

    public init(context: Context) {
        let context = context.newScope()

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 300, height: 48)

        searchModel = MediaSearchModelCollection()
        filteredModel = FilteredModelCollection(sourceCollection: searchModel)

        super.init(
            model: filteredModel,
            modelBinder: DefaultViewModelBindingProvider(),
            viewBinder: AppViewBindingProvider(),
            layout: layout,
            context: context)

        self.navigationItem.titleView = searchBar
        self.navigationItem.rightBarButtonItem = barItemForContentFilter(.all)
        self.modelObserver = searchModel.observeValues { [weak self] event in
            if case .didChangeState(let state) = event {
                guard let strongSelf = self else { return }
                if state.isLoading {
                    strongSelf.navigationItem.rightBarButtonItem = strongSelf.barItemForLoading()
                } else {
                    let item = strongSelf.barItemForContentFilter(strongSelf.contentFilter)
                    strongSelf.navigationItem.rightBarButtonItem = item
                }
            }
        }
    }

    // MARK: CollectionViewController

    public override func displayForNoContentState() -> EmptyCollectionDisplay {
        let query = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let emptyLabel = UILabel()
        emptyLabel.numberOfLines = 0
        emptyLabel.textColor = .lightGray
        emptyLabel.textAlignment = .center
        emptyLabel.text = query.isEmpty ? "🔍 for Podcasts, TV Episodes\n or Songs on iTunes" : "No Results"
        return .view(emptyLabel)
    }

    // MARK: UIViewController

    public override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
    }

    // MARK: FlowLayoutDelegate

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let defaultSize = CGSize(width: collectionView.bounds.width, height: 48.0)
        let available = AvailableSize(
            defaultSize: defaultSize,
            maxSize: CGSize(width: collectionView.bounds.width, height: 1000.0))
        return dataSource.preferredLayoutForItemAtIndexPath(indexPath, availableSize: available).size ?? defaultSize
    }

    // MARK: UISearchBarDelegate

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let query = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        searchModel.updateQuery(query)
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let query = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        searchModel.updateQuery(query)
    }

    @objc
    private func filterAction() {
        let alert = UIAlertController(title: "Filter", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "All ⭐️", style: .default, handler: { _ in
            self.contentFilter = .all
        }))
        alert.addAction(UIAlertAction(title: "Podcasts 🎙", style: .default, handler: { _ in
            self.contentFilter = .podcast
        }))
        alert.addAction(UIAlertAction(title: "Songs 🎵", style: .default, handler: { _ in
            self.contentFilter = .songs
        }))
        alert.addAction(
            UIAlertAction(
                title: "TV Episodes 📺",
                style: .default,
                handler: { _ in self.contentFilter = .televisionEpisodes }))
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: Private

    private enum ContentType {
        case all
        case podcast
        case songs
        case televisionEpisodes

        var label: String {
            switch self {
            case .all: return "⭐️"
            case .podcast: return "🎙"
            case .songs: return "🎵"
            case .televisionEpisodes: return "📺"
            }
        }
    }

    private var contentFilter: ContentType = .all {
        didSet {
            navigationItem.rightBarButtonItem = barItemForContentFilter(contentFilter)
            let content = contentFilter
            filteredModel.filter = { model in
                switch content {
                case .all:
                    return true
                case .podcast:
                    return model is Podcast
                case .songs:
                    return model is Song
                case .televisionEpisodes:
                    return model is TelevisionEpisode
                }
            }
        }
    }

    private func barItemForLoading() -> UIBarButtonItem {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        let item = UIBarButtonItem(customView: activityIndicator)
        activityIndicator.startAnimating()
        return item
    }

    private func barItemForContentFilter(_ contentFilter: ContentType) -> UIBarButtonItem {
        return UIBarButtonItem(
            title: contentFilter.label,
            style: .plain,
            target: self,
            action: #selector(filterAction))
    }

    private var modelObserver: Subscription?
    private let searchBar = UISearchBar()
    private let searchModel: MediaSearchModelCollection
    private let filteredModel: FilteredModelCollection
}
