import UIKit
import Pilot
import PilotUI
import SafariServices
import AVFoundation
import AVKit
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private var navigationController: UINavigationController? {
        return window?.rootViewController as? UINavigationController
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
    ) -> Bool {

        _ = PublishSubject<Void>()
        
        contextObserver = context.receiveAll { [weak self] (action) -> ActionResult in
            if let action = action as? ViewURLAction {
                self?.pushWebView(url: action.url)
                return .handled
            } else if let action = action as? ViewMediaAction {
                self?.pushMediaViewer(url: action.url)
                return .handled
            } else {
                return .notHandled
            }
        }

        navigationController?.viewControllers = [MediaSearchViewController(context: context)]
        return true
    }

    private func pushMediaViewer(url: URL) {
        let playerViewController = AVPlayerViewController()
        playerViewController.player = AVPlayer(url: url)
        navigationController?.pushViewController(playerViewController, animated: true)
    }

    private func pushWebView(url: URL) {
        let webViewController = WebViewController(url: url)
        navigationController?.pushViewController(webViewController, animated: true)
    }

    private let context = Context()
    private var contextObserver: Subscription?
}
