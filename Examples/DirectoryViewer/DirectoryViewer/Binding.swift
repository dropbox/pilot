import Pilot

public struct DirectoryModelBinder: ViewModelBindingProvider {
    public func viewModel(for model: Model, context: Context) -> ViewModel {
        return FileViewModel(model: model, context: context)
    }

    public func selectionViewModel(for models: [Model], context: Context) -> SelectionViewModel? {
        let files: [FileViewModel] = models.flatMap({ ($0 as? File)?.viewModelWithContext(context) as? FileViewModel })
        return FileSelectionViewModel(viewModels: files, context: context)
    }
}

public struct FileSelectionViewModel: SelectionViewModel {
    public init(viewModels: [ViewModel], context: Context) {
        self.files = viewModels.map { $0.typedViewModel() }
        self.context = context
    }

    public var files: [FileViewModel]
    public var context: Context

    // MARK: ViewModelType

    public func canHandleUserEvent(_ event: ViewModelUserEvent) -> Bool {
        for file in files {
            if !file.canHandleUserEvent(event) {
                return false
            }
        }
        return true
    }

    public func handleUserEvent(_ event: ViewModelUserEvent) {
        for file in files {
            file.handleUserEvent(event)
        }
    }

    public func secondaryActions(for event: ViewModelUserEvent) -> [SecondaryAction] {
        let names = files.map({ $0.filename }).joined(separator: ",")
        let action = OpenFilesAction(urls: files.map({ $0.url }))
        let title = files.count == 1 ? "Open" : "Open \(files.count) files"
        let open = SecondaryActionInfo(metadata: SecondaryActionInfo.Metadata.init(title: title), action: action)
        return [.info("Selected: \(names)"), .action(open)]
    }
}
