import UIKit
import Pilot
import PilotUI
import RxSwift
import RxCocoa

public final class MediaSearchViewController: CollectionViewController, UISearchBarDelegate, UICollectionViewDelegateFlowLayout {

    public init(context: Context) {
        let context = context.newScope()

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 300, height: 48)

        let service = SearchService()

        self.query = BehaviorSubject(value: "")
        self.filter = BehaviorSubject(value: .all)

        let media: Observable<(String, ModelCollectionState)> = query
            .throttle(0.5, latest: true, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMap { (query) in
                service.search(query)
                    .asObservable()
                    .mappedToResult()
                    .map { (query, $0) }
                    .share()
            }
            .map { (q, result) in
                let state: ModelCollectionState
                switch result {
                case .success(let media): state = .loaded(media)
                case .failure(let error): state = .error(error)
                }
                return (q, state)
            }
            .share()

        let model: ModelCollection = Observable
            .combineLatest(query, media) { (currentQuery, result) in
                let (resultQuery, state) = result
                // If the current query doesn't start with the query the results are for ignore them
                guard currentQuery.hasPrefix(resultQuery) else {
                    return .loading(nil)
                }
                if currentQuery == resultQuery {
                    return state
                } else {
                    return .loading(state.models)
                }
            }
            .observeOn(MainScheduler.instance)

        let filteredModel: ModelCollection = Observable
            .combineLatest(model, filter) { (state, type) in
                let modelFilter: (Model) -> Bool = {
                    switch type {
                    case .all:
                        return true
                    case .podcast:
                        return $0 is Podcast
                    case .songs:
                        return $0 is Song
                    case .televisionEpisodes:
                        return $0 is TelevisionEpisode
                    }
                }

                switch state {
                case .notLoaded, .error:
                    return state
                case .loading(let models):
                    return .loading(models?.filter(modelFilter))
                case .loaded(let models):
                    return .loaded(models.filter(modelFilter))
                }
            }

        super.init(
            model: filteredModel,
            modelBinder: DefaultViewModelBindingProvider(),
            viewBinder: AppViewBindingProvider(),
            layout: layout,
            context: context)

        self.navigationItem.titleView = searchBar
        self.navigationItem.rightBarButtonItem = barItemForContentFilter(.all)

        model
            .subscribe(onNext: { [weak self] (state) in
                guard let strongSelf = self else { return }
                if state.isLoading {
                    strongSelf.navigationItem.rightBarButtonItem = strongSelf.barItemForLoading()
                } else {
                    let item = strongSelf.barItemForContentFilter(strongSelf.contentFilter)
                    strongSelf.navigationItem.rightBarButtonItem = item
                }
            })
            .disposed(by: disposeBag)
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
        query.onNext(searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        query.onNext(searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
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

    private let disposeBag = DisposeBag()
    private let query: BehaviorSubject<String>
    private let filter: BehaviorSubject<ContentType>
    private let searchBar = UISearchBar()

    // MARK: Content Filtering

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
            filter.onNext(content)
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
}
