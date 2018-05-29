# Getting Started

This guide will use Pilot to step through building a basic iTunes Store Search application for iOS and macOS. By the end, the reader should have a good understanding of:

- The core Model-View-ViewModel (MVVM) stack, how it may differ from other implementations of MVVM, and how it supports a unidirectional data flow.
- How `ModelCollection` acts as the foundation for composable data collections and handles updates.
- How all important logic can be unit tested at the `ViewModel` layer, without any dependency on a specific UI framework.
- How user actions are handled and processed.

## Building an iTunes Search app 

Our app will be leverage a simple API that takes a search query and returns a JSON response of results from the iTunes store. The API takes the form: `https://itunes.apple.com/search?term=siracusa&limit=100`

Pilot does not dictate how your application fetches from the network or stores data locally (although making that easier is on the roadmap). For the purposes of this example, we'll use a very basic [SearchService](../Examples/iTunesSearch/Shared/SearchService.swift) class to take a query string, and item fetch limit to fetch our JSON from the above API.

```swift
class SearchService {
  func search(
    term: String,
    limit: Int,
    completion: @escaping ([Media]?, ServiceError?) -> Void
  ) {
    // ...
  }
```

Don't worry about why it's returning `[Media]` just yet, we'll cover how the JSON gets converted shortly. And yes, there are better signatures for that completion block, but we're keeping things simple.

Now that we have a basic search API, we want to start piping that data into Pilot. To do so, we start with our first core protocol, `Model`.

## `Model`

In Pilot, a [`Model`](../Core/Source/MVVM/Model.swift) is a protocol that represents a **value type of pure stateless data**. For nearly all applications, this represents "one of the things in your scrolling list" — in this case, a result from an iTunes Search. In your application, it may be a message in a group chat, a post in a news feed, a comment in a thread, or a task in your todo app.

In our application, the JSON from iTunes returns a list of model objects. Here is a song:

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

Representing this data in Swift would look like this:

```swift
struct Song {
  var artistId: Int
  var collectionId: Int
  var trackId: Int
  var artistName: String
  var collectionName: String
  var trackName: String
  var preview: URL
  var artwork: URL?
  var durationMilliseconds: Int
  var trackNumber: Int?
  var trackCount: Int?
}
```

Your model object doesn't have to come from JSON, it could come from Core Data, SQLite, or any other source. 

> How to serialize & deserialize from your data source into a model struct like the above example is beyond the scope of this document.

The example application happens to leverage Swift's `Decodable` implementation on the `Song` struct to deflate from JSON.

Conformance to `Model` is quite simple, as there are only two properties to implement:

- `modelId` is a string that guarantees uniqueness for that model object across your application.
- `modelVersion` is a hash that represents the version of that object and lets Pilot know if important model data has changed.

These two properties are used to provide automated delta updates across any heterogeneous collection of model objects. We'll see more about that later on.

For our `Song`, we can conform to `Model` with the following code:

```swift
extension Song: Model {
    
  var modelId: ModelId { return String(trackId) }
    
  var modelVersion: ModelVersion { ... }
}
```

Implementing `modelId` was easy, as iTunes already has a unique track id for its results — so we return that.

However, iTunes does not have a concept of a version for a given song — the only way to know if any song metadata has changed is to look at the metadata itself. No problem! If your server or data source has no concept of version, Pilot has a handy `ModelVersionMixer` class that lets you combine important metadata into an efficient hashed value. For `Song`, we would want to mix in all the metadata to contribute to the hash. Then if any metadata changes, the version will change:

```swift    
  var modelVersion: ModelVersion {
        var mixer = ModelVersionMixer()
        mixer.mix(artistId)
        mixer.mix(collectionId)
        mixer.mix(trackId)
        mixer.mix(artistName)
        mixer.mix(collectionName)
        mixer.mix(trackName)
        mixer.mix(artistViewUrl.absoluteString)
        mixer.mix(collectionViewUrl.absoluteString)
        mixer.mix(trackViewUrl.absoluteString)
        mixer.mix(previewUrl.absoluteString)
        if let artwork = artworkUrl100 {
            mixer.mix(artwork.absoluteString)
        }
        mixer.mix(Float64(collectionPrice))
        mixer.mix(Float64(trackPrice))
        mixer.mix(releaseDate)
        mixer.mix(trackTimeMillis)
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

And we're done defining our `Model` for Songs. The example app also adds `TelevisionEpisode` and `Podcast`, as iTunes returns results for those as well.

## `ViewModel`

Now that we have a model representing a Song, things can get more interesting.
  
In Pilot, a `ViewModel` is bound to a specific `Model` type and has the following responsibilities:

- Implement any necessary application business logic atop the bound `Model` object.
- Expose properties for the view to display. If those properties change over time (e.g. a relative timestamp), those properties should be [observable](../Core/Source/Observable/ObservableData.swift).
- Handle all user interactions by emitting `Action` types.

Given these responsibilities, the `View` that displays data from a `ViewModel` will be purposely underwhelming — it will simply connect `ViewModel` properties to whatever UI framework is being used.

Let's dig a bit deeper on how to implement `ViewModel` before discussing some key benefits. Most of the methods on the `ViewModel` protocol have default implementations, so conformance only requires an initializer and public read-only variable:

```swift
public struct SongViewModel: ViewModel {    

  // MARK: ViewModel
  
  public init(model: Model, context: Context) {
    self.song = model.typedModel()
    self.context = context
  }
  public let context: Context
    
  // MARK: Private
    
  private let song: Song
}
```

The required initializer has two parameters:

- The `Context` object has two responsibilities: it supplies any application-specific dependencies your view model may need and it acts as the mechanism for sending actions from the view model. More detail about how `Context` accomplishes this is covered below.

- The `Model` object, in this case, will be the `Song` struct we created above. View models are lifetime-bound to a specific `Model` type with a single `modelVersion`. If that model object gets updated, Pilot will create a new `ViewModel` object and initialize it with the updated `Model`.

You'll notice that the signature of the initializer uses `Model` rather than `Song`. This is due to a [limitation in Swift generics](https://github.com/apple/swift/blob/master/docs/GenericsManifesto.md#generalized-existentials). As a workaround, Pilot provides the `typedModel()` helper to easily downcast to the specific model type your view model expects. When Swift supports more ergonomic usage of protocols with associated types, Pilot will be able to strongly type the initializer by default.

> Later on, when discussing binding, you'll see a technique where you can upgrade a `ViewModel` to have a strongly-typed initializer. In our `SongViewModel` case, the signature will evolve to `init(song: Song, context: MyAppContext)`.

So far, our view model is just holding onto the `Context` and the `Song`. Next, let's add an example property that demonstrates some application business logic:

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

While this is simple example, it illustrates the kind of responsibilities a view model should have: taking the model data, and deciding what to do with it and how to present it. The above example conditionally formats a general description string to be displayed next to the song title.

We start to see how the `ViewModel` is easily unit tested, without the need for involving UI or other application objects:

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

Pilot `ViewModel`s are self-contained, which make them ideal for unit testing:

- The immutable model does not change throughout the lifetime of the view model.
- Everything needed by the view model is provided at initialization.
- More complex view models are provided dependencies via the `Context`, which can be mocked, stubbed, or faked in testing.

Here is the full `SongViewModel` from the iTunes Search example:

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

Before we learn about how View Models respond to and act upon user interaction, let's finish the end-to-end display of our `Song`.

### `View`

Unlike view models, `View` classes

```swift
public final class SongView: UIView, View {

  public func bindToViewModel(_ viewModel: ViewModel) {
    let songVM: SongViewModel = viewModel.typedViewModel()
    self.songVM = songVM
    
    nameLabel.text = songVM.name
    descriptionLabel.text = songVM.description
    durationLabel.text = songVM.duration
    
    if let artwork = songVM.artwork {
      // Rudimentary image fetch - your app would likely
      // have something better.
      URLSession.shared.imageTask(with: artwork, completionHandler: { [weak self] (image, error) in
        if let image = image, artwork == self?.songVM?.artwork {
          self?.imageView.image = image
        }
      }).resume()
    } else {
      imageView.image = nil
    }
  }
}

public var viewModel: ViewModel? {
    return songVM
}
```

- [ ] TODO for @wkiefer

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

- [ ] TODO for @wkiefer

```swift
  static func preferredLayout(
    fitting availableSize: AvailableSize,
    for viewModel: ViewModel
  ) -> PreferredLayout {
    return .Size(CGSize(width: availableSize.maxSize.width, height: 50))
  }
```

## Binding

- [ ] TODO for @wkiefer

```swift
extension Song: ViewModelConvertible {
  public func viewModelWithContext(_ context: Context) -> ViewModel {
    return SongViewModel(model: self, context: context)
  }
}
```

- [ ] TODO for @wkiefer. alternative around a specific binding


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

- [ ] TODO for @wkiefer. maybe add a note about a strongly-typed initializer

## `ModelCollection`

- [ ] TODO for @wkiefer
    - composition, and types of MCs
    - sections

## PilotUI Bindings

- [ ] TODO for @wkiefer. collection view controller

## User Interaction

- [ ] TODO for @wkiefer

## `Action`

- [ ] TODO for @wkiefer

## `Context`

- [ ] TODO for @wkiefer. providing context and acting as a responder chain


## Future Work

- [ ] TODO for @wkiefer. using a ViewModel as the core VC logic, making that easier. formalizing the store


