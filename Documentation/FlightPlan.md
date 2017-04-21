# Flight Plan

Pilot is young and full of hope -- below is a rough flight plan of upcoming features and components. Each leg clusters a set of related functionality. There is no specific timing associated with each leg, but they are in prioritized order.

Features may shift slightly during the flight, depending on feedback and requests.

### Leg 1

- [x] Core MVVM stack.
- [x] Core `Observable` and `Action` idiom.
- [x] `UICollectionView` bindings.
- [x] `NSCollectionView` bindings.

### Leg 2

- [ ] `UITableView` bindings.
- [ ] `NSTableView` bindings.
- [ ] `Context` improvements.
- [ ] Analytics & logging formalization in the MVVM stack.
- [ ] Better `rebind` per-view animated delta support.

### Leg 3

- [ ] PilotRx library providing optional [RxSwift](https://github.com/ReactiveX/RxSwift) integration.
- [ ] Additional composable `ModelCollection` implementations.
- [ ] `NSOutlineView` bindings.

### Leg 4

- [ ] `Store` and `Service` library.
- [ ] Formalized `Router` 
- [ ] Formalized application routing and flow control.

---

### Future Legs

- [ ] `View` adds a `VieWModel` associated type for more strongly-typed bindings (pending Swift generics changes).
- [ ] Android support (pending [Swift](https://github.com/apple/swift) & [CoreLibs](https://github.com/apple/swift-corelibs-foundation) support).
- [ ] Android bindings.
- [ ] Windows support (pending [Swift](https://github.com/apple/swift) & [CoreLibs](https://github.com/apple/swift-corelibs-foundation) support).
- [ ] Windows bindings.
- [ ] Better support for NS/UI control binding.
- [ ] Better support for non-data-bound MVVM patterns (i.e. larger UI surface support)
- [ ] Better XIB support.
