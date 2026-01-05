import SwiftUI

struct ContentView: View {
    var body: some View {
        if let url = URL(string: "https://railway.com") {
            WebView(url: url)
                .frame(minWidth: 800, minHeight: 600)
                .edgesIgnoringSafeArea(.all)
        } else {
            Text("Failed to load Railway")
                .frame(minWidth: 800, minHeight: 600)
        }
    }
}
