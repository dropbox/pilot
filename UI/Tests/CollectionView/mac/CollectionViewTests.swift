import XCTest
import Pilot
@testable import PilotUI

class CollectionViewTests: XCTestCase {

    /// Assert that the CollectionViewController renders a View with appropriate ViewModel and Model.
    func testBasicCollectionViewBinding() {
        let cvc = makeCollectionViewController()

        guard let hostedView: TestView = view(from: cvc, at: IndexPath(item: 0, section: 0)) else {
            XCTFail("CollectionViewController has no hostedView of type TestView")
            return
        }

        guard let viewModel = hostedView.viewModel as? TestViewModel else  {
            XCTFail("TestView has no viewModel of type TestViewModel")
            return
        }

        XCTAssert(viewModel.model.modelId == "MODEL_1")
    }

    /// Assert that the CollectionViewController renders a supplementary View with appropriate ViewModel and Model.
    func testSupplementaryCollectionViewBinding() {
        let kind = TestSupplementaryLayout.SupplementaryLayoutKind
        let path = IndexPath(item: 0, section: 0)

        let layout = TestSupplementaryLayout()
        let cvc = makeCollectionViewController(layout: layout)
        applySupplementaryViewBindings(to: cvc)

        guard let view: TestView = supplementaryView(from: cvc, forKind: kind, at: path) else {
            XCTFail("CollectionViewController has no supplementary view of type TestView")
            return
        }

        guard let viewModel = view.viewModel as? TestViewModel else  {
            XCTFail("TestView has no viewModel of type TestViewModel")
            return
        }

        XCTAssert(viewModel.model.modelId == "SUPPLEMENTARY_MODEL_1")
    }

    /// Assert that the CollectionViewController renders a supplementary View with appropriate ViewModel and Model
    /// and that the view can be rebound even if the underlying View type changes.
    func testSupplementaryCollectionViewBindingReload() {
        let kind = TestSupplementaryLayout.SupplementaryLayoutKind
        let path = IndexPath(item: 0, section: 0)

        let layout = TestSupplementaryLayout()
        let cvc = makeCollectionViewController(layout: layout)
        applySupplementaryViewBindings(to: cvc)

        // We should be able to reload a supplementary view with same View type.
        cvc.dataSource.reloadSupplementaryElementAtIndexPath(indexPath: path, kind: kind.rawValue)

        // Switch out the View type to a different one.
        cvc.dataSource.clearViewBinderForSupplementaryElementOfKind(kind.rawValue)
        cvc.dataSource.setViewBinder(
            BlockViewBindingProvider { _, _ in ViewBinding(AltTestView.self) },
            forSupplementaryElementOfKind: kind.rawValue)

        cvc.dataSource.reloadSupplementaryElementAtIndexPath(indexPath: path, kind: kind.rawValue)

        guard let view: AltTestView = supplementaryView(from: cvc, forKind: kind, at: path) else {
            XCTFail("CollectionViewController has no supplementary view of type AltTestView")
            return
        }

        guard let viewModel = view.viewModel as? TestViewModel else  {
            XCTFail("TestView has no viewModel of type TestViewModel")
            return
        }

        XCTAssert(viewModel.model.modelId == "SUPPLEMENTARY_MODEL_1")
    }

    // MARK: Helpers

    func view<V: View>(from cvc: CollectionViewController, at indexPath: IndexPath) -> V? {
        let item = cvc.collectionView.item(at: indexPath)
        guard let hostedView = (item as? CollectionViewHostItem)?.hostedView as? V else {
            return nil
        }
        return hostedView
    }

    func supplementaryView<V: View>(
        from cvc: CollectionViewController,
        forKind kind: NSCollectionView.SupplementaryElementKind,
        at indexPath: IndexPath
    ) -> V? {
        let item = cvc.collectionView.supplementaryView(forElementKind: kind, at: indexPath)
        guard let hostedView = (item as? CollectionViewHostReusableView)?.hostedView as? V else {
            return nil
        }
        return hostedView
    }

    func makeCollectionViewController(layout: NSCollectionViewLayout = makeDefaultLayout()) -> CollectionViewController {
        let context = Context()
        let collection = StaticModelCollection([StaticModel(modelId: "MODEL_1", data: "First")])

        let cvc = CollectionViewController(
            model: collection,
            modelBinder: BlockViewModelBindingProvider { TestViewModel(model: $0, context: $1) },
            viewBinder: BlockViewBindingProvider { _, _ in ViewBinding(TestView.self) },
            layout: layout,
            context: context)

        cvc.loadView()
        cvc.preferredContentSize = NSSize(width: 100, height: 100)
        cvc.viewDidLoad()
        cvc.view.frame = NSRect(x: 0, y: 0, width: 200, height: 200)

        return cvc
    }

    func applySupplementaryViewBindings(to cvc: CollectionViewController) {
        let kind = TestSupplementaryLayout.SupplementaryLayoutKind
        cvc.dataSource.setModelProvider(
            provider: BlockModelProvider { _, _ in StaticModel(modelId: "SUPPLEMENTARY_MODEL_1", data: Void()) },
            forSupplementaryElementOfKind: kind.rawValue)
        cvc.dataSource.setViewModelBinder(
            BlockViewModelBindingProvider { TestViewModel(model: $0, context: $1) },
            forSupplementaryElementOfKind: kind.rawValue)
        cvc.dataSource.setViewBinder(
            BlockViewBindingProvider { _, _ in ViewBinding(TestView.self) },
            forSupplementaryElementOfKind: kind.rawValue)
        cvc.collectionView.layout()
    }
}

private func makeDefaultLayout() -> NSCollectionViewLayout {
    let layout = NSCollectionViewFlowLayout()
    layout.itemSize = NSSize(width: 20, height: 20)
    return layout
}

fileprivate struct TestViewModel: ViewModel {
    fileprivate init(model: Model, context: Context) {
        self.model = model
        self.context = context
    }

    fileprivate let model: Model
    fileprivate var context: Context
}

fileprivate final class TestView: NSView, View {
    fileprivate var viewModel: ViewModel?

    fileprivate func bindToViewModel(_ viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    fileprivate func unbindFromViewModel() {
        self.viewModel = nil
    }
}

fileprivate final class AltTestView: NSView, View {
    fileprivate var viewModel: ViewModel?

    fileprivate func bindToViewModel(_ viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    fileprivate func unbindFromViewModel() {
        self.viewModel = nil
    }
}

fileprivate final class TestSupplementaryLayout: NSCollectionViewLayout {
    fileprivate static let SupplementaryLayoutKind = NSCollectionView.SupplementaryElementKind.sectionHeader

    fileprivate override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {

        var layoutAttrs = [NSCollectionViewLayoutAttributes]()

        if let attrs = layoutAttributesForItem(at: IndexPath(item: 0, section: 0)) {
            layoutAttrs.append(attrs)
        }

        if let attrs = layoutAttributesForSupplementaryView(ofKind: TestSupplementaryLayout.SupplementaryLayoutKind, at: IndexPath(item: 0, section: 0)) {
            layoutAttrs.append(attrs)
        }

        return layoutAttrs
    }

    fileprivate override func layoutAttributesForItem(at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
        let attrs = NSCollectionViewLayoutAttributes(forItemWith: indexPath)
        attrs.frame = NSRect(x: 0, y: 0, width: 20, height: 20)
        return attrs
    }

    fileprivate override func layoutAttributesForSupplementaryView(
        ofKind elementKind: NSCollectionView.SupplementaryElementKind,
        at indexPath: IndexPath
    ) -> NSCollectionViewLayoutAttributes? {
        let attrs = NSCollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
        attrs.frame = NSRect(x: 0, y: 0, width: 20, height: 20)
        return attrs
    }
}
