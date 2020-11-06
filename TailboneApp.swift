import SwiftUI
import WebKit

struct ContentView: View {
    var webview = Webview.init(url: Bundle.main.url(
        forResource: "index",
        withExtension: "html"
    )!)
    var body: some View {
        webview
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

final class Webview: UIViewRepresentable {
    var url: URL

    init(url: URL) {
      self.url = url
    }

    func makeUIView(
        context: UIViewRepresentableContext<Webview>
    ) -> WKWebView {
        let config = WKWebViewConfiguration()

        // enable audio playback to begin immediately
        config.mediaTypesRequiringUserActionForPlayback = []

        // ensure window.webkit.messageHandlers is present for index.html to
        // detect the platform correctly and skip the web-only menu screen
        let contentController = WKUserContentController()
        contentController.add(
            ViewController.init(),
            name: "placeholder"
        )
        config.userContentController = contentController

        let webview = WKWebView(
            frame: .zero,
            configuration: config
        )

        // prevent white flash during load
        webview.isOpaque = false
        webview.backgroundColor = UIColor.clear

        // prevent haptic feedback during long presses
        let recognizer = UILongPressGestureRecognizer(
            target: self, action:
            #selector(longPress)
        )
        webview.addGestureRecognizer(recognizer)

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

    @objc func longPress() {
        // Do nothing. This is only here to suppress long
        // press gestures and avoid the haptic feedback when
        // the player is holding down a tap to float longer.
    }
}


@main
struct TailboneApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
