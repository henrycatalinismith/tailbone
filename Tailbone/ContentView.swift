import SwiftUI
import WebKit

struct ContentView: View {
    let url = Bundle.main.url(
        forResource: "index",
        withExtension: "html"
    )
    var body: some View {
        Webview(url: url!)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}

class ViewController: UIViewController, WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        // Do nothing. This is only here to give the JS something to detect
        // so that it can skip the web version's start menu.
    }
}

struct Webview: UIViewRepresentable {
    let url: URL

    func makeUIView(
        context: UIViewRepresentableContext<Webview>
    ) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(
            ViewController.init(),
            name: "placeholder"
        )

        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []
        config.userContentController = contentController

        let webview = WKWebView(
            frame: .zero,
            configuration: config
        )
        let request = URLRequest(
            url: self.url,
            cachePolicy: .returnCacheDataElseLoad
        )
        webview.load(request)
        return webview
    }

    func updateUIView(
        _ webview: WKWebView,
        context: UIViewRepresentableContext<Webview>
    ) {
        let request = URLRequest(
            url: self.url,
            cachePolicy: .returnCacheDataElseLoad
        )
        webview.load(request)
    }
}
