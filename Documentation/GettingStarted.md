# Getting Started

TODO

## Core Concepts

Three interfaces make up conceptual core of the Pilot stack:

- [**`Model`**](../Core/Source/MVVM/Model.swift): Value type which represents pure stateless data.
	- Exposes an id for uniqueness and version for updates.
- [**`ViewModel`**](../Core/Source/MVVM/ViewModel.swift): Value type bound to a specific `Model` type.
	- Implements application business logic atop the `Model`.
	- Handles user events by emitting actions.
	- Independently unit testable with simple inputs (`Model` and events) and outputs (properties and emitted actions).
- [**`View`**](../Core/Source/MVVM/View.swift): A reference type for direct presentation of a specific `ViewModel`. 
	- Typically implemented in the UI layer (e.g. `NSView` or `UIView`) - but has no actual UI dependency so supports a wide range of presentations (e.g. console applications).

The stack enforces a unidirectional data flow and strict layering: `Model` -> `ViewModel` -> `View`. 

### Binding

The mapping from a specific `Model` to `ViewModel` or `ViewModel` to `View` (represented by the arrows above) is called **binding**. In Pilot, binding happens via the `ViewModelBindingProvider` and `ViewBindingProvider` interfaces. 

While simple applications may only need a single binding provider, the flexibility of using multiple binding providers allows for more complex applications to map the same data to different view models or view presentations in different parts of the app.

### `ModelCollection`

The [`ModelCollection`](../Core/Source/MVVM/ModelCollection.swift) type represents a collection of `Model` objects and provides an observable stream of its state changes.

While seemingly simple, `ModelCollection` instances work in tandem with the view controllers provided by `PilotUI.framework` to drive incremental updates, handle view setup and teardown, manage binding providers, display loading and error states, and more.

Applications may implement custom `ModelCollection` types, however, Pilot provides a set of composable `ModelCollection` implementations which allow applications to easily map, filter, reduce, and multiplex collections, as well as handle asynchronous loads from the network or local storage.

The end result is that by TODO

### `Action` and `Context`



## Building a sample app 

### `Model`

todo

```json
{
	"kind": "song",
	"artistId": 5448756,
	"collectionId": 719245563,
	"trackId": 719245998,
	"artistName": "The Long Winters",
	"collectionName": "Ultimatum - EP",
	"trackName": "The Commander Thinks Aloud",
	"previewUrl": "http://audio.itunes.apple.com/apple-assets-us-std-000001/<snipped>/.m4a",
	"artworkUrl100": "http://is2.mzstatic.com/image/thumb/<snipped>/100x100bb.jpg",
	"trackTimeMillis": 326053,
	"trackNumber": 1,
	"trackCount": 6,
	// ...
}
```

would map to

```swift
public struct Song: Model {
	public var artistId: Int
	public var collectionId: Int
	public var trackId: Int
	public var artistName: String
	public var collectionName: String
	public var trackName: String
	public var preview: URL
	public var artwork: URL?
	public var durationMilliseconds: Int
	public var trackNumber: Int?
	public var trackCount: Int?
}
```

conform to `Model`

```swift
extension Song: Model {
	public var modelId: ModelId { return String(trackId) }
	public var modelVersion: ModelVersion { ... }
```

then


```swift	
	public var modelVersion: ModelVersion {
		var mixer = ModelVersionMixer()
		mixer.mix(artistId)
		mixer.mix(collectionId)
		mixer.mix(trackId)
		mixer.mix(artistName)
		mixer.mix(collectionName)
		mixer.mix(trackName)
		mixer.mix(preview.absoluteString)
		if let artwork = artwork {
			mixer.mix(artwork.absoluteString)
		}
		mixer.mix(durationMilliseconds)
		if let trackNumber = trackNumber {
			mixer.mix(trackNumber)
		}
		if let trackCount = trackCount {
			mixer.mix(trackCount)
		}
		return mixer.result()
	}
}
```

you'd have inflate. example app has `init?(json: [String: Any])`

### `ViewModel`

```swift
public struct SongViewModel: ViewModel {	
	public init(model: Model, context: Context) {
		self.song = model.typedModel()
		self.context = context
	}
	public let context: Context
	private let song: Song
}
```

more



ff

```swift
public struct SongViewModel: ViewModel {
	// ...
		
	public var description: String {
		if let number = song.trackNumber {
			if let count = song.trackCount {
				return "Track \(number)/\(count) · \(collectionName)"
			}
			return "Track \(number) · \(collectionName)"
		}
		return collectionName
	}
```

foo

```swift
class SongViewModelTests: XCTestCase {
    func testDescriptionWithTrackInfo() {
        let collectionName = stubSong.collectionName
        var song = stubSong
        song.trackCount = 2
        song.trackNumber = 1
        let subject = SongViewModel(model: song, context: Context())
        let expected = "Track 1/2 · " + collectionName
        XCTAssertEqual(subject.description, expected, "Include track # and total if it exists")
    }
    func testDescriptionWithNoTrackInfo() { ... }
    func testDescriptionWithNoTrackCount() { ... }
```

ff

```swift

public struct SongViewModel: ViewModel {
	
	// MARK: ViewModel
	
	public init(model: Model, context: Context) { ... }
	public let context: Context
	
	// MARK: Public

	public var name: String {
		return song.trackName
	}
	
	public var description: String {
		if let number = song.trackNumber {
			if let count = song.trackCount {
				return "Track \(number)/\(count) · \(collectionName)"
			}
			return "Track \(number) · \(collectionName)"
		}
		return collectionName
	}
	
	public var collectionName: String {
		return song.collectionName
	}
	
	public var duration: String {
	    let totalSeconds = song.durationMilliseconds / 1000
	    let hours = totalSeconds / 3600
	    let minutes = (totalSeconds % 3600) / 60
	    let seconds = (totalSeconds % 60)
	    if hours > 0 {
	        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
	    } else if minutes > 0 {
	        return String(format: "%02d:%02d", minutes, seconds)
	    } else {
	        return String(format: "%02d", seconds)
	    }
	}
	
	public var artwork: URL? {
	    return song.artwork
	}
	
	// MARK: Private
	
	private let song: Song
}
```

### `View`

```swift
final class SongView: UIView, View {

	public func bindToViewModel(_ viewModel: ViewModel) {
		let song: SongViewModel = viewModel.typedViewModel()
	
		nameLabel.text = song.name
		descriptionLabel.text = song.description
		durationLabel.text = song.duration
	
		if let artwork = song.artwork {
			// Rudimentary image fetch - your app would likely
			// have something better.
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
}
```

then

```swift
final class SongView: UIView, View {
	// ...
	
	public func unbindFromViewModel() {
		nameLabel.text = nil
		descriptionLabel.text = nil
		durationLabel.text = nil
		imageView.image = nil
		song = nil
	}
```

optional layout info

```swift
	static func preferredLayout(
		fitting availableSize: AvailableSize,
		for viewModel: ViewModel
	) -> PreferredLayout {
		return .Size(CGSize(width: availableSize.maxSize.width, height: 50))
	}
```

### Binding

```swift
extension Song: ViewModelConvertible {
	public func viewModelWithContext(_ context: Context) -> ViewModel {
		return SongViewModel(model: self, context: context)
	}
}
```

```swift
struct AppViewBindingProvider: ViewBindingProvider {

    // MARK: ViewBindingProvider

    func viewBinding(for viewModel: ViewModel, context: Context) -> ViewBinding {
        switch viewModel {
        case is PodcastViewModel:
            return ViewBinding(PodcastView.self)
        case is SongViewModel:
            return ViewBinding(SongView.self)
        case is TelevisionEpisodeViewModel:
            return ViewBinding(TelevisionEpisodeView.self)
        default:
            fatalError("No supported view binding class available.")
        }
    }
```

### `ModelCollection`

### PilotUI Bindings

### `Action`

### `Context`


