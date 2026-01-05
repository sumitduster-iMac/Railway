import SwiftUI

@main
struct RailwayApp: App {
    @StateObject private var web = WebViewModel()

    init() {
        // Give the app a real-looking icon in the Dock / Cmd-Tab even if the bundle
        // icon hasn't been customized yet.
        RailwayBranding.applyRuntimeAppIconIfPossible()
    }

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

enum RailwayBranding {
    static func applyRuntimeAppIconIfPossible() {
        #if os(macOS)
        guard let icon = makeIconImage(size: NSSize(width: 512, height: 512)) else { return }
        NSApplication.shared.applicationIconImage = icon
        #endif
    }

    #if os(macOS)
    private static func makeIconImage(size: NSSize) -> NSImage? {
        let image = NSImage(size: size)
        image.lockFocusFlipped(false)
        defer { image.unlockFocus() }

        guard let context = NSGraphicsContext.current?.cgContext else { return nil }
        context.saveGState()
        defer { context.restoreGState() }

        let rect = CGRect(origin: .zero, size: size)
        let radius = min(size.width, size.height) * 0.22
        let path = NSBezierPath(roundedRect: rect.insetBy(dx: size.width * 0.08, dy: size.height * 0.08),
                                xRadius: radius,
                                yRadius: radius)
        path.addClip()

        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                NSColor.systemBlue.cgColor,
                NSColor.systemPink.cgColor,
            ] as CFArray,
            locations: [0.0, 1.0]
        )
        if let gradient {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: rect.minX, y: rect.maxY),
                end: CGPoint(x: rect.maxX, y: rect.minY),
                options: []
            )
        }

        // Subtle vignette for depth.
        let vignette = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                NSColor.black.withAlphaComponent(0.0).cgColor,
                NSColor.black.withAlphaComponent(0.22).cgColor,
            ] as CFArray,
            locations: [0.0, 1.0]
        )
        if let vignette {
            context.drawRadialGradient(
                vignette,
                startCenter: CGPoint(x: rect.midX, y: rect.midY),
                startRadius: min(size.width, size.height) * 0.05,
                endCenter: CGPoint(x: rect.midX, y: rect.midY),
                endRadius: min(size.width, size.height) * 0.65,
                options: []
            )
        }

        // Center SF Symbol.
        let symbolName = "train.side.front.car"
        guard let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else { return image }

        let symbolRect = rect.insetBy(dx: size.width * 0.30, dy: size.height * 0.30)
        let config = NSImage.SymbolConfiguration(pointSize: symbolRect.width, weight: .semibold)
        let configured = symbol.withSymbolConfiguration(config) ?? symbol

        let tinted = configured.copy() as? NSImage ?? configured
        tinted.isTemplate = true

        NSColor.white.withAlphaComponent(0.92).set()
        tinted.draw(in: symbolRect, from: .zero, operation: .sourceAtop, fraction: 1.0)

        return image
    }
    #endif
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
