import SwiftUI

struct ContentView: View {
    var body: some View {
        WebView(url: URL(string: "https://railway.com")!)
            .frame(minWidth: 800, minHeight: 600)
            .edgesIgnoringSafeArea(.all)
    }
}
