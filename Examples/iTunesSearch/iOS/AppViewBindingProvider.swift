import Pilot
import PilotUI
import UIKit

internal struct AppViewBindingProvider: ViewBindingProvider {

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

    func preferredLayout(
        fitting availableSize: AvailableSize,
        for viewModel: ViewModel,
        context: Context
    ) -> PreferredLayout {
        let viewType = viewBinding(for: viewModel, context: context).viewType
        return viewType.preferredLayout(fitting: availableSize, for: viewModel)
    }
}
