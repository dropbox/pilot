import UIKit
import Pilot
import AVFoundation

final class TelevisionEpisodeView: UIView, View {

    init() {
        super.init(frame: .zero)
        loadSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View

    public func bindToViewModel(_ viewModel: ViewModel) {
        let episode: TelevisionEpisodeViewModel = viewModel.typedViewModel()

        nameLabel.text = episode.name
        collectionLabel.text = episode.collectionName
        descriptionLabel.text = episode.description

        imageView.image = nil

        if let localPreview = episode.localPreview {
            let asset = AVAsset(url: localPreview)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            let middle = CMTimeMultiplyByRatio(asset.duration, 1, 2)
            if let rawImage = try? imageGenerator.copyCGImage(at: middle, actualTime: nil) {
                imageView.image = UIImage(cgImage: rawImage)
            }
        }

        if let artwork = episode.artwork, imageView.image == nil {
            URLSession.shared.imageTask(with: artwork, completionHandler: { [weak self] (image, error) in
                if let image = image, artwork == self?.episode?.artwork {
                    self?.imageView.image = image
                }
            }).resume()
        }

        self.episode = episode
    }

    public func unbindFromViewModel() {
        episode = nil
    }

    public var viewModel: ViewModel? { return episode }

    static func preferredLayout(
        fitting availableSize: AvailableSize,
        for viewModel: ViewModel
    ) -> PreferredLayout {
        return .Size(CGSize(width: availableSize.maxSize.width, height: 100))
    }

    // MARK: Private

    private var episode: TelevisionEpisodeViewModel?

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

        addSubview(televisionIcon)
        televisionIcon.translatesAutoresizingMaskIntoConstraints = false
        televisionIcon.rightAnchor.constraint(equalTo: rightAnchor, constant: -6).isActive = true
        televisionIcon.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        televisionIcon.text = "📺"
        televisionIcon.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)

        addSubview(nameLabel)
        nameLabel.font = UIFont.boldSystemFont(ofSize: 15)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.topAnchor.constraint(equalTo: imageView.topAnchor).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: imageView.rightAnchor, constant: 6).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: televisionIcon.leftAnchor, constant: -6).isActive = true

        addSubview(collectionLabel)
        collectionLabel.font = UIFont.systemFont(ofSize: 10)
        collectionLabel.translatesAutoresizingMaskIntoConstraints = false
        collectionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor).isActive = true
        collectionLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor).isActive = true
        collectionLabel.rightAnchor.constraint(equalTo: nameLabel.rightAnchor).isActive = true

        descriptionLabel.numberOfLines = 0

        addSubview(descriptionLabel)
        descriptionLabel.textColor = UIColor.darkGray
        descriptionLabel.font = UIFont.italicSystemFont(ofSize: 10)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.topAnchor.constraint(equalTo: collectionLabel.bottomAnchor).isActive = true
        descriptionLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6).isActive = true
        descriptionLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor).isActive = true
        descriptionLabel.rightAnchor.constraint(equalTo: nameLabel.rightAnchor).isActive = true
    }

    private let nameLabel = UILabel()
    private let collectionLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let imageView = UIImageView()
    private let televisionIcon = UILabel()
}
