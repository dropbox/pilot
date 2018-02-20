import XCTest
@testable import iTunesSearch

class ServiceTypes: XCTestCase {

    func testExample() {

        let testString = "{\"wrapperType\":\"track\",\"kind\":\"song\",\"artistId\":909253,\"collectionId\":879273552,\"trackId\":879273565,\"artistName\":\"Jack Johnson\",\"collectionName\":\"In Between Dreams\",\"trackName\":\"Better Together\",\"collectionCensoredName\":\"In Between Dreams\",\"trackCensoredName\":\"Better Together\",\"artistViewUrl\":\"https://itunes.apple.com/us/artist/jack-johnson/id909253?uo=4\",\"collectionViewUrl\":\"https://itunes.apple.com/us/album/better-together/id879273552?i=879273565&uo=4\",\"trackViewUrl\":\"https://itunes.apple.com/us/album/better-together/id879273552?i=879273565&uo=4\",\"previewUrl\":\"http://a25.phobos.apple.com/us/r30/Music6/v4/13/22/67/1322678b-e40d-fb4d-8d9b-3268fe03b000/mzaf_8818596367816221008.plus.aac.p.m4a\",\"artworkUrl30\":\"http://is3.mzstatic.com/image/thumb/Music2/v4/a2/66/32/a2663205-663c-8301-eec7-57937c2d0878/source/30x30bb.jpg\",\"artworkUrl60\":\"http://is3.mzstatic.com/image/thumb/Music2/v4/a2/66/32/a2663205-663c-8301-eec7-57937c2d0878/source/60x60bb.jpg\",\"artworkUrl100\":\"http://is3.mzstatic.com/image/thumb/Music2/v4/a2/66/32/a2663205-663c-8301-eec7-57937c2d0878/source/100x100bb.jpg\",\"collectionPrice\":10.99,\"trackPrice\":1.29,\"releaseDate\":\"2005-03-01T08:00:00Z\",\"collectionExplicitness\":\"notExplicit\",\"trackExplicitness\":\"notExplicit\",\"discCount\":1,\"discNumber\":1,\"trackCount\":15,\"trackNumber\":1,\"trackTimeMillis\":207679,\"country\":\"USA\",\"currency\":\"USD\",\"primaryGenreName\":\"Rock\",\"isStreamable\":true}"

        guard
            let data = testString.data(using: .utf8),
            let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any]
        else {
            XCTFail()
            return
        }

        let model = Song(json: json)
        XCTAssertNotNil(model)
    }
}
