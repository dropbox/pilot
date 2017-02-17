import UIKit
import Pilot

final class SongView: UIView, View {

    init() {
        super.init(frame: .zero)
        loadSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View

    public func bindToViewModel(_ viewModel: ViewModel) {
        let song: SongViewModel = viewModel.typedViewModel()

        nameLabel.text = song.name
        descriptionLabel.text = song.description
        durationLabel.text = song.duration

        if let artwork = song.artwork {
            URLSession.shared.imageTask(with: artwork, completionHandler: { [weak self] (image, error) in
                if let image = image, artwork == self?.song?.artwork {
                    self?.imageView.image = image
                }
            }).resume()
        } else {
            imageView.image = nil
        }

        self.song = song
    }

    public func unbindFromViewModel() {
        nameLabel.text = nil
        descriptionLabel.text = nil
        durationLabel.text = nil
        imageView.image = nil
        song = nil
    }

    public var viewModel: ViewModel? { return song }

    static func preferredLayout(
        fitting availableSize: AvailableSize,
        for viewModel: ViewModel
    ) -> PreferredLayout {
        return .Size(CGSize(width: availableSize.maxSize.width, height: 50))
    }

    // MARK: Private

    private var song: SongViewModel?

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
        songIcon.text = "🎵"
        songIcon.translatesAutoresizingMaskIntoConstraints = false
        songIcon.rightAnchor.constraint(equalTo: rightAnchor, constant: -6).isActive = true
        songIcon.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        songIcon.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        songIcon.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)

        let labelContainer = UIView()
        labelContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(labelContainer)
        labelContainer.leftAnchor.constraint(equalTo: imageView.rightAnchor, constant: 6).isActive = true
        labelContainer.rightAnchor.constraint(equalTo: songIcon.leftAnchor, constant: -6).isActive = true
        labelContainer.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        labelContainer.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh-1, for: .horizontal)

        labelContainer.addSubview(durationLabel)
        durationLabel.font = UIFont(name: "Courier", size: 10)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.rightAnchor.constraint(equalTo: labelContainer.rightAnchor).isActive = true
        durationLabel.centerYAnchor.constraint(equalTo: labelContainer.centerYAnchor).isActive = true
        durationLabel.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        durationLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)

        labelContainer.addSubview(nameLabel)
        nameLabel.font = UIFont.boldSystemFont(ofSize: 15)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.topAnchor.constraint(equalTo: labelContainer.topAnchor).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: labelContainer.leftAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: durationLabel.leftAnchor).isActive = true
        nameLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh-1, for: .horizontal)

        labelContainer.addSubview(descriptionLabel)
        descriptionLabel.font = UIFont.italicSystemFont(ofSize: 10)
        descriptionLabel.textColor = .darkGray
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor).isActive = true
        descriptionLabel.leftAnchor.constraint(equalTo: labelContainer.leftAnchor).isActive = true
        descriptionLabel.rightAnchor.constraint(equalTo: durationLabel.leftAnchor).isActive = true
        descriptionLabel.bottomAnchor.constraint(equalTo: labelContainer.bottomAnchor).isActive = true
        descriptionLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh-1, for: .horizontal)
    }

    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let durationLabel = UILabel()
    private let imageView = UIImageView()
    private let songIcon = UILabel()
}
