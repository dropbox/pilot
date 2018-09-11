import UIKit
import Pilot
import PilotUI
import RxSwift
import RxCocoa

public final class MediaSearchViewController: CollectionViewController, UICollectionViewDelegateFlowLayout {

    public init(context: Context) {
        let context = context.newScope()

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 300, height: 48)

        self.searchQuery =  BehaviorRelay(value: "")
        self.contentFilter = BehaviorRelay(value: .all)

        let service = SearchService()
        let media = searchQuery
            .throttle(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest {
                service.search(term: $0, limit: 100).asObservable().retry(3).startWith(nil)
            }
            .observeOn(MainScheduler.instance)

        let mediaFilter = contentFilter.map { $0.match(_:) }
        
        let model = Observable.combineLatest(media, mediaFilter)
            .mappedModelCollection { (media, mediaFilter) in
                guard let media = media else { return .loading(nil) }
                return .loaded(media.filter(mediaFilter))
            }

        super.init(
            model: model,
            modelBinder: DefaultViewModelBindingProvider(),
            viewBinder: AppViewBindingProvider(),
            layout: layout,
            context: context)
    }

    // MARK: CollectionViewController

    public override func displayForNoContentState() -> EmptyCollectionDisplay {
        let query = searchQuery.value.trimmingCharacters(in: .whitespacesAndNewlines)
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

        let searchBar = UISearchBar()
        self.navigationItem.titleView = searchBar

        searchBar.rx.text
            .map({ $0 ?? "" })
            .bind(to: searchQuery)
            .disposed(by: disposeBag)

        let loading = self.dataSource.currentCollection.stateObservable().map({ $0.isLoading })

        Observable<UIBarButtonItem>
            .combineLatest(loading, contentFilter) { (loading, filter) in
                if loading {
                    return MediaSearchViewController.barItemForLoading()
                } else {
                    return MediaSearchViewController.barItemForContentFilter(filter)
                }
            }
            .bind(onNext: { [weak self] in self?.navigationItem.rightBarButtonItem = $0 })
            .disposed(by: disposeBag)
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

    @objc
    private func filterAction() {
        let alert = UIAlertController(title: "Filter", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "All ⭐️", style: .default, handler: { _ in
            self.contentFilter.accept(.all)
        }))
        alert.addAction(UIAlertAction(title: "Podcasts 🎙", style: .default, handler: { _ in
            self.contentFilter.accept(.podcast)
        }))
        alert.addAction(UIAlertAction(title: "Songs 🎵", style: .default, handler: { _ in
            self.contentFilter.accept(.songs)
        }))
        alert.addAction(
            UIAlertAction(
                title: "TV Episodes 📺",
                style: .default,
                handler: { _ in self.contentFilter.accept(.televisionEpisodes) }))
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

        func match(_ media: Media) -> Bool {
            switch self {
            case .all: return true
            case .podcast: return media is Podcast
            case .songs: return media is Song
            case .televisionEpisodes: return media is TelevisionEpisode
            }
        }
    }

    private static func barItemForLoading() -> UIBarButtonItem {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        let item = UIBarButtonItem(customView: activityIndicator)
        activityIndicator.startAnimating()
        return item
    }

    private static func barItemForContentFilter(_ contentFilter: ContentType) -> UIBarButtonItem {
        return UIBarButtonItem(
            title: contentFilter.label,
            style: .plain,
            target: self,
            action: #selector(filterAction))
    }

    private let disposeBag = DisposeBag()
    private let searchQuery: BehaviorRelay<String>
    private let contentFilter: BehaviorRelay<ContentType>
}
