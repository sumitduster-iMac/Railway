import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var web: WebViewModel

    @State private var showLoading: Bool = true
    @State private var loadingFadeOut: Bool = false

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                NavigationBar(web: web)
                Divider().opacity(0.12)

                ZStack(alignment: .top) {
                    WebView(model: web)
                        .frame(minWidth: 800, minHeight: 600)

                    if web.isLoading {
                        ProgressView(value: web.estimatedProgress)
                            .progressViewStyle(.linear)
                            .tint(LinearGradient(colors: [Color.blue, Color.pink], startPoint: .leading, endPoint: .trailing))
                            .padding(.horizontal, 14)
                            .padding(.top, 8)
                    }

                    if let message = web.lastErrorMessage {
                        ErrorCard(message: message, reload: web.reload, openInBrowser: web.openInBrowser)
                            .padding(.top, 72)
                    }
                }

                Divider().opacity(0.12)
                StatusBar(web: web)
            }
            .frame(minWidth: 800, minHeight: 600)
            .background(.clear)

            if showLoading {
                LoadingOverlay(isFading: loadingFadeOut)
                    .transition(.opacity)
            }
        }
        .background(WindowConfigurator())
        .onAppear {
            web.loadHome()
            Task { @MainActor in
                // Match the reference: show a polished loading screen briefly.
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation(.easeOut(duration: 0.5)) {
                    loadingFadeOut = true
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
                withAnimation(.easeOut(duration: 0.2)) {
                    showLoading = false
                }
            }
        }
    }
}

// MARK: - UI components (Lovable-style shell)

private struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(red: 0.06, green: 0.09, blue: 0.16), Color(red: 0.12, green: 0.16, blue: 0.23)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private struct NavigationBar: View {
    @ObservedObject var web: WebViewModel

    private var hostText: String {
        web.currentURL?.host ?? "railway.com"
    }

    var body: some View {
        HStack(spacing: 10) {
            NavButton(system: "chevron.left", help: "Back", enabled: web.canGoBack) {
                web.goBack()
            }
            NavButton(system: "chevron.right", help: "Forward", enabled: web.canGoForward) {
                web.goForward()
            }
            NavButton(system: "arrow.clockwise", help: "Reload", enabled: true) {
                if web.isLoading { web.stopLoading() } else { web.reload() }
            }

            Spacer(minLength: 10)

            UrlPill(text: hostText)

            Spacer(minLength: 10)

            NavButton(system: "house", help: "Home", enabled: true) {
                web.loadHome()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.12))
        .overlay {
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.blue.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct NavButton: View {
    let system: String
    let help: String
    let enabled: Bool
    let action: () -> Void

    @State private var hovering: Bool = false

    var body: some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary.opacity(enabled ? 0.95 : 0.35))
                .frame(width: 32, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(hovering && enabled ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.blue.opacity(0.20), lineWidth: 1)
                        .opacity(hovering && enabled ? 1 : 0.6)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .help(help)
        .onHover { hovering = $0 }
    }
}

private struct UrlPill: View {
    let text: String
    @State private var hovering: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "globe")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LinearGradient(colors: [Color.blue, Color.pink], startPoint: .leading, endPoint: .trailing))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.95))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(hovering ? 0.22 : 0.16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.blue.opacity(0.22), lineWidth: 1)
        )
        .onHover { hovering = $0 }
        .help(webDisplayHint)
        .contextMenu {
            Button("Copy URL") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            }
        }
    }

    private var webDisplayHint: String {
        "Current site"
    }
}

private struct StatusBar: View {
    @ObservedObject var web: WebViewModel

    private var statusText: String {
        if !web.isOnline { return "Offline" }
        if web.lastErrorMessage != nil { return "Disconnected" }
        return "Connected"
    }

    private var statusColor: Color {
        if !web.isOnline || web.lastErrorMessage != nil { return Color.red.opacity(0.9) }
        return Color.green.opacity(0.9)
    }

    private var versionText: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        let v = short ?? "1.0.0"
        if let build, !build.isEmpty { return "Railway Desktop v\(v) (\(build))" }
        return "Railway Desktop v\(v)"
    }

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                PulsingDot(color: statusColor, isActive: web.isOnline && web.lastErrorMessage == nil)
                Text(statusText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.85))
            }
            Spacer()
            Text(versionText)
                .font(.system(size: 12))
                .foregroundStyle(.secondary.opacity(0.9))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.10))
    }
}

private struct PulsingDot: View {
    let color: Color
    let isActive: Bool
    @State private var pulse: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.25))
                .frame(width: 10, height: 10)
                .scaleEffect(pulse && isActive ? 1.8 : 1.0)
                .opacity(pulse && isActive ? 0.0 : 1.0)
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.35), radius: 6, x: 0, y: 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
        .accessibilityLabel(isActive ? "Connected" : "Disconnected")
    }
}

private struct ErrorCard: View {
    let message: String
    let reload: () -> Void
    let openInBrowser: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("Couldn’t load this page")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
                .frame(maxWidth: 560)
            HStack(spacing: 10) {
                Button("Reload", action: reload)
                    .keyboardShortcut("r", modifiers: [.command])
                Button("Open in Browser", action: openInBrowser)
            }
        }
        .padding(22)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.blue.opacity(0.20), lineWidth: 1)
        )
        .padding(.horizontal, 18)
    }
}

private struct LoadingOverlay: View {
    let isFading: Bool
    @State private var pulse: Bool = false
    @State private var bounce: Bool = false

    var body: some View {
        ZStack {
            AppBackground()
                .overlay(Color.black.opacity(0.25))

            VStack(spacing: 16) {
                LogoMark(pulse: pulse)
                    .padding(.top, 10)

                ShimmerText("Railway")
                    .font(.system(size: 44, weight: .bold, design: .default))

                DotLoader(bounce: bounce)

                Text("Initializing your deployment workspace…")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.60))
                    .padding(.top, 6)
            }
            .opacity(isFading ? 0.0 : 1.0)
            .animation(.easeOut(duration: 0.5), value: isFading)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                bounce = true
            }
        }
    }
}

private struct LogoMark: View {
    let pulse: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: [Color.blue, Color.pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 84, height: 84)
                .shadow(color: Color.pink.opacity(0.22), radius: 22, x: 0, y: 10)
                .scaleEffect(pulse ? 1.04 : 0.98)

            Image(systemName: "train.side.front.car")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.92))
        }
        .accessibilityHidden(true)
    }
}

private struct DotLoader: View {
    let bounce: Bool

    var body: some View {
        HStack(spacing: 8) {
            LoaderDot(delay: 0.0, bounce: bounce)
            LoaderDot(delay: 0.15, bounce: bounce)
            LoaderDot(delay: 0.30, bounce: bounce)
        }
        .padding(.top, 4)
        .accessibilityLabel("Loading")
    }
}

private struct LoaderDot: View {
    let delay: Double
    let bounce: Bool

    var body: some View {
        Circle()
            .fill(LinearGradient(colors: [Color.blue, Color.pink], startPoint: .top, endPoint: .bottom))
            .frame(width: 8, height: 8)
            .offset(y: bounce ? -4 : 4)
            .opacity(0.9)
            .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true).delay(delay), value: bounce)
    }
}

private struct ShimmerText: View {
    let text: String
    @State private var phase: CGFloat = -0.8

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .foregroundStyle(
                LinearGradient(
                    stops: [
                        .init(color: Color.blue.opacity(0.95), location: 0),
                        .init(color: Color.pink.opacity(0.95), location: 0.5),
                        .init(color: Color.blue.opacity(0.95), location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay {
                GeometryReader { proxy in
                    let w = proxy.size.width
                    LinearGradient(
                        colors: [Color.white.opacity(0.0), Color.white.opacity(0.45), Color.white.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: w * 0.35)
                    .rotationEffect(.degrees(20))
                    .offset(x: w * phase)
                    .blendMode(.screen)
                }
                .mask(Text(text))
            }
            .onAppear {
                withAnimation(.linear(duration: 2.6).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
    }
}

/// Configures the hosting NSWindow to feel like a native "hiddenInset"-style app.
private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        ConfiguratorView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class ConfiguratorView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }

            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true

            window.minSize = NSSize(width: 800, height: 600)
            if window.frame.size.width < 800 || window.frame.size.height < 600 {
                window.setContentSize(NSSize(width: 1400, height: 900))
                window.center()
            }
        }
    }
}
