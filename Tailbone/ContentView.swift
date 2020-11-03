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

struct Webview: UIViewRepresentable {
    let url: URL

    func makeUIView(
        context: UIViewRepresentableContext<Webview>
    ) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []
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
