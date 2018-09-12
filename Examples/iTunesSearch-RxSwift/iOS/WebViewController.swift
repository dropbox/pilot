import UIKit
import WebKit

public class WebViewController: UIViewController {

    public init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        let webView = WKWebView(frame: .zero)
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        // Setting this to avoid the automatic redirect that is broken in the simulator.
        webView.customUserAgent = "Mozilla/5.0 Mobile iTunesSearch Demo"
        webView.load(URLRequest(url: url))
    }

    private let url: URL
}
