import SwiftUI

enum RailwaySection: String, CaseIterable, Identifiable {
    case home
    case dashboard
    case templates
    case docs
    case status

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .dashboard: return "Dashboard"
        case .templates: return "Templates"
        case .docs: return "Docs"
        case .status: return "Status"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .dashboard: return "rectangle.3.group"
        case .templates: return "square.grid.2x2"
        case .docs: return "book"
        case .status: return "waveform.path.ecg"
        }
    }

    var url: URL {
        switch self {
        case .home:
            return URL(string: "https://railway.com")!
        case .dashboard:
            return URL(string: "https://railway.com/dashboard")!
        case .templates:
            return URL(string: "https://railway.com/templates")!
        case .docs:
            return URL(string: "https://docs.railway.com")!
        case .status:
            return URL(string: "https://status.railway.app")!
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var web: WebViewModel

    @State private var selection: RailwaySection? = .dashboard

    var body: some View {
        NavigationSplitView {
            List(RailwaySection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section as RailwaySection?)
            }
            .navigationTitle("Railway")
        } detail: {
            ZStack(alignment: .top) {
                WebView(model: web)
                    .frame(minWidth: 980, minHeight: 640)

                if web.isLoading {
                    ProgressView(value: web.estimatedProgress)
                        .progressViewStyle(.linear)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                }

                if let message = web.lastErrorMessage {
                    VStack(spacing: 10) {
                        Text("Couldn’t load this page")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text(message)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .textSelection(.enabled)
                            .frame(maxWidth: 520)
                        HStack {
                            Button("Reload") { web.reload() }
                                .keyboardShortcut("r", modifiers: [.command])
                            Button("Open in Browser") { web.openInBrowser() }
                        }
                    }
                    .padding(22)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.top, 60)
                }
            }
            .navigationTitle(web.title)
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    Button {
                        web.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .help("Back")
                    .disabled(!web.canGoBack)

                    Button {
                        web.goForward()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .help("Forward")
                    .disabled(!web.canGoForward)
                }

                ToolbarItemGroup {
                    Button {
                        if web.isLoading { web.stopLoading() } else { web.reload() }
                    } label: {
                        Image(systemName: web.isLoading ? "xmark" : "arrow.clockwise")
                    }
                    .help(web.isLoading ? "Stop" : "Reload")

                    Divider()

                    Button {
                        selection = .dashboard
                        web.load(RailwaySection.dashboard.url)
                    } label: {
                        Image(systemName: "bolt.fill")
                    }
                    .help("Dashboard")

                    Button {
                        selection = .home
                        web.load(RailwaySection.home.url)
                    } label: {
                        Image(systemName: "house")
                    }
                    .help("Home")
                }

                ToolbarItemGroup(placement: .automatic) {
                    Button {
                        web.openInBrowser()
                    } label: {
                        Image(systemName: "safari")
                    }
                    .help("Open in Browser")
                }
            }
            .onAppear {
                if let selection {
                    web.load(selection.url)
                } else {
                    web.load(RailwaySection.dashboard.url)
                }
            }
            .onChange(of: selection) { _, newValue in
                guard let section = newValue else { return }
                web.load(section.url)
            }
        }
    }
}
