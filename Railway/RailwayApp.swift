import SwiftUI

@main
struct RailwayApp: App {
    @StateObject private var web = WebViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(web)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
            RailwayCommands(web: web)
        }

        Settings {
            SettingsView()
                .environmentObject(web)
        }
    }
}

struct RailwayCommands: Commands {
    let web: WebViewModel

    var body: some Commands {
        CommandMenu("Navigate") {
            Button("Back") { web.goBack() }
                .keyboardShortcut("[", modifiers: [.command])
                .disabled(!web.canGoBack)

            Button("Forward") { web.goForward() }
                .keyboardShortcut("]", modifiers: [.command])
                .disabled(!web.canGoForward)

            Divider()

            Button("Reload") { web.reload() }
                .keyboardShortcut("r", modifiers: [.command])

            Button("Open in Browser") { web.openInBrowser() }
                .keyboardShortcut("o", modifiers: [.command, .shift])
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var web: WebViewModel
    @State private var isClearing: Bool = false

    var body: some View {
        Form {
            Section("Browsing") {
                Toggle("Open external links in default browser", isOn: $web.openExternalLinksInBrowser)
                    .toggleStyle(.switch)
                Text("When enabled, links outside Railway will open in Safari to keep this app focused on Railway.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Storage") {
                Button(isClearing ? "Clearing…" : "Clear website data") {
                    isClearing = true
                    Task {
                        await web.clearWebsiteData()
                        isClearing = false
                    }
                }
                .disabled(isClearing)

                Text("This clears cookies and cached data used by the embedded Railway site.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(width: 520)
    }
}
