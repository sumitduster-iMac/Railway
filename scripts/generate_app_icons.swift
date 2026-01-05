import AppKit
import Foundation

// Generates a simple Railway-branded macOS AppIcon set (PNG files) into the given
// AppIcon.appiconset directory. This keeps the repo binary-free while still
// producing a real app icon during builds (CI and local).
//
// Usage:
//   /usr/bin/swift scripts/generate_app_icons.swift "<path-to-AppIcon.appiconset>"

func fail(_ message: String) -> Never {
    fputs("error: \(message)\n", stderr)
    exit(1)
}

guard CommandLine.arguments.count >= 2 else {
    fail("missing output directory argument (AppIcon.appiconset)")
}

let outputDir = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)

let specs: [(filename: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

func makeIconImage(pixels: Int) -> NSImage? {
    let size = NSSize(width: pixels, height: pixels)
    let image = NSImage(size: size)
    image.lockFocusFlipped(false)
    defer { image.unlockFocus() }

    guard let context = NSGraphicsContext.current?.cgContext else { return nil }
    context.saveGState()
    defer { context.restoreGState() }

    let rect = CGRect(origin: .zero, size: size)
    let inset = CGFloat(pixels) * 0.08
    let radius = CGFloat(pixels) * 0.22
    let rounded = NSBezierPath(roundedRect: rect.insetBy(dx: inset, dy: inset), xRadius: radius, yRadius: radius)
    rounded.addClip()

    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [NSColor.systemBlue.cgColor, NSColor.systemPink.cgColor] as CFArray,
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

    let vignette = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [NSColor.black.withAlphaComponent(0.0).cgColor, NSColor.black.withAlphaComponent(0.22).cgColor] as CFArray,
        locations: [0.0, 1.0]
    )
    if let vignette {
        context.drawRadialGradient(
            vignette,
            startCenter: CGPoint(x: rect.midX, y: rect.midY),
            startRadius: CGFloat(pixels) * 0.05,
            endCenter: CGPoint(x: rect.midX, y: rect.midY),
            endRadius: CGFloat(pixels) * 0.65,
            options: []
        )
    }

    let symbolName = "train.side.front.car"
    guard let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else { return image }
    let symbolRect = rect.insetBy(dx: CGFloat(pixels) * 0.30, dy: CGFloat(pixels) * 0.30)
    let config = NSImage.SymbolConfiguration(pointSize: symbolRect.width, weight: .semibold)
    let configured = symbol.withSymbolConfiguration(config) ?? symbol

    let tinted = configured.copy() as? NSImage ?? configured
    tinted.isTemplate = true
    NSColor.white.withAlphaComponent(0.92).set()
    tinted.draw(in: symbolRect, from: .zero, operation: .sourceAtop, fraction: 1.0)

    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "generate_app_icons", code: 1, userInfo: [NSLocalizedDescriptionKey: "failed to encode PNG"])
    }
    try png.write(to: url, options: [.atomic])
}

for spec in specs {
    let outURL = outputDir.appendingPathComponent(spec.filename)
    if FileManager.default.fileExists(atPath: outURL.path) {
        continue
    }
    guard let img = makeIconImage(pixels: spec.pixels) else {
        fail("failed to render icon for \(spec.pixels)x\(spec.pixels)")
    }
    do {
        try writePNG(img, to: outURL)
    } catch {
        fail("failed to write \(spec.filename): \(error.localizedDescription)")
    }
}

print("✅ App icons ensured in \(outputDir.path)")
