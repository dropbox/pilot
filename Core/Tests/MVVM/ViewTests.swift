@testable import Pilot
import XCTest

class ViewTests: XCTestCase {

    func testDefaultRebind() {
        let subject = InspectableView()
        subject.bindToViewModel(StubViewModel())
        subject.rebindToViewModel(StubViewModel())
        XCTAssertEqual(subject.bindCount, 2)
        XCTAssertEqual(subject.unbindCount, 1)
    }

    func testOverrideRebind() {
        let subject = CustomRebindView()
        subject.bindToViewModel(StubViewModel())
        subject.rebindToViewModel(StubViewModel())
        XCTAssertEqual(subject.rebindCount, 1)
    }
}

fileprivate struct StubViewModel: ViewModel {
    init() {
        self.init(model: StaticModel(modelId: UUID().uuidString, data: ""), context: Context())
    }

    init(model: Model, context: Context) {
        self.context = context
    }
    var context: Context
}

fileprivate final class InspectableView: View {
    var viewModel: ViewModel?

    var bindCount = 0
    var unbindCount = 0

    func bindToViewModel(_ viewModel: ViewModel) { bindCount += 1 }
    func unbindFromViewModel() { unbindCount += 1 }
}

fileprivate final class CustomRebindView: View {
    var viewModel: ViewModel?

    func bindToViewModel(_ viewModel: ViewModel) {}
    func unbindFromViewModel() {}

    var rebindCount = 0
    func rebindToViewModel(_ viewModel: ViewModel) { rebindCount += 1 }
}
