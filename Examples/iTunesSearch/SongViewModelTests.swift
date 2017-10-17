import XCTest
import Pilot
@testable import iTunesSearch

class SongViewModelTests: XCTestCase {

    func testDescriptionWithNoTrackInfo() {
        let collectionName = stubSong.collectionName
        var song = stubSong
        song.trackCount = nil
        song.trackNumber = nil
        let subject = SongViewModel(model: song, context: Context())
        XCTAssertEqual(subject.description, collectionName, "If there's not track info description be collectionName")
    }

    func testDescriptionWithNoTrackCount() {
        let collectionName = stubSong.collectionName
        var song = stubSong
        song.trackCount = nil
        song.trackNumber = 1
        let subject = SongViewModel(model: song, context: Context())
        let expected = "Track 1 · " + collectionName
        XCTAssertEqual(subject.description, expected, "Include track # if there's a track # but no count")
    }

    func testDescriptionWithTrackInfo() {
        let collectionName = stubSong.collectionName
        var song = stubSong
        song.trackCount = 2
        song.trackNumber = 1
        let subject = SongViewModel(model: song, context: Context())
        let expected = "Track 1/2 · " + collectionName
        XCTAssertEqual(subject.description, expected, "Include track # and total if it exists")
    }

    func testSelectionEmitsAViewMediaAction() {
        let song = stubSong
        let context = Context()
        let subject = SongViewModel(model: song, context: context)
        let result = subject.action(.select)
        if let result = result as? ViewMediaAction {
            XCTAssertEqual(result.url, song.preview)
        } else {
            XCTFail("Expected a 'ViewMediaAction' for .select events. Got \(String(describing: result)).")
        }
    }
}

private let stubSong = Song(
    artistId: 42,
    collectionId: 3159,
    trackId: 1,
    artistName: "You've probably never heard of them",
    collectionName: "Self-titled",
    trackName: "Untitled",
    artistView: URL(string: "https://en.wikipedia.org/wiki/Creed_(band)")!,
    collectionView: URL(string: "https://en.wikipedia.org/wiki/My_Own_Prison")!,
    trackView: URL(string: "https://en.wikipedia.org/wiki/My_Own_Prison_(song)")!,
    preview: URL(string: "https://en.wikipedia.org/wiki/My_Own_Prison_(song)?preview=true")!,
    artwork: nil,
    collectionPrice: 1.1,
    trackPrice: 9.9,
    release: Date(timeIntervalSince1970: 0),
    durationMilliseconds: 42,
    trackNumber: 1,
    trackCount: 112)
