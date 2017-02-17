import UIKit
import Pilot

final class PodcastView: UIView, View {

    init() {
        super.init(frame: .zero)
        loadSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View

    public func bindToViewModel(_ viewModel: ViewModel) {
        let podcast: PodcastViewModel = viewModel.typedViewModel()

        nameLabel.text = podcast.name
        artistName.text = podcast.artistName

        if let artwork = podcast.artwork {
            URLSession.shared.imageTask(with: artwork, completionHandler: { [weak self] (image, error) in
                if let image = image, artwork == self?.podcast?.artwork {
                    self?.imageView.image = image
                }
            }).resume()
        } else {
            imageView.image = nil
        }

        self.podcast = podcast
    }

    public func unbindFromViewModel() {
        podcast = nil
    }

    public var viewModel: ViewModel? { return podcast }

    static func preferredLayout(
        fitting availableSize: AvailableSize,
        for viewModel: ViewModel
    ) -> PreferredLayout {
        return .Size(CGSize(width: availableSize.maxSize.width, height: 75))
    }

    // MARK: Private

    private var podcast: PodcastViewModel?

    private func loadSubviews() {
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 6).isActive = true
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
        imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6).isActive = true

        imageView.layer.cornerRadius = 3
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = .lightGray

        addSubview(songIcon)
        songIcon.text = "🎙"
        songIcon.translatesAutoresizingMaskIntoConstraints = false
        songIcon.rightAnchor.constraint(equalTo: rightAnchor, constant: -6).isActive = true
        songIcon.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        songIcon.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)

        let labelContainer = UIView()
        labelContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(labelContainer)
        labelContainer.leftAnchor.constraint(equalTo: imageView.rightAnchor, constant: 6).isActive = true
        labelContainer.rightAnchor.constraint(equalTo: songIcon.leftAnchor, constant: -6).isActive = true
        labelContainer.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        addSubview(nameLabel)
        nameLabel.font = UIFont.boldSystemFont(ofSize: 15)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.topAnchor.constraint(equalTo: labelContainer.topAnchor).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: labelContainer.leftAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: labelContainer.rightAnchor).isActive = true

        addSubview(artistName)
        artistName.font = UIFont.italicSystemFont(ofSize: 10)
        artistName.textColor = .darkGray
        artistName.translatesAutoresizingMaskIntoConstraints = false
        artistName.topAnchor.constraint(equalTo: nameLabel.bottomAnchor).isActive = true
        artistName.leftAnchor.constraint(equalTo: labelContainer.leftAnchor).isActive = true
        artistName.rightAnchor.constraint(equalTo: labelContainer.rightAnchor).isActive = true
        artistName.bottomAnchor.constraint(equalTo: labelContainer.bottomAnchor).isActive = true
    }

    private let nameLabel = UILabel()
    private let artistName = UILabel()
    private let imageView = UIImageView()
    private let songIcon = UILabel()
}
