#!/usr/bin/env swift
// Draws the Verba app icon at every size macOS needs and writes an .iconset folder.
//
// Usage: swift scripts/make-icon.swift <output .iconset directory>
//
// The artwork is a violet tile with a waveform whose bars form a "V" (for Verba),
// and a single amber bar in the middle that doubles as a text cursor.
import AppKit

struct IconSize {
    let name: String
    let pixels: Int
}

let sizes: [IconSize] = [
    IconSize(name: "icon_16x16", pixels: 16),
    IconSize(name: "icon_16x16@2x", pixels: 32),
    IconSize(name: "icon_32x32", pixels: 32),
    IconSize(name: "icon_32x32@2x", pixels: 64),
    IconSize(name: "icon_128x128", pixels: 128),
    IconSize(name: "icon_128x128@2x", pixels: 256),
    IconSize(name: "icon_256x256", pixels: 256),
    IconSize(name: "icon_256x256@2x", pixels: 512),
    IconSize(name: "icon_512x512", pixels: 512),
    IconSize(name: "icon_512x512@2x", pixels: 1024)
]

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

func barRects() -> [NSRect] {
    let heights: [CGFloat] = [440, 340, 250, 160, 250, 340, 440]
    let barWidth: CGFloat = 66
    let gap: CGFloat = 36
    let total = CGFloat(heights.count) * barWidth + CGFloat(heights.count - 1) * gap
    var originX = (1024 - total) / 2

    return heights.map { height in
        let rect = NSRect(x: originX, y: 512 - height / 2, width: barWidth, height: height)
        originX += barWidth + gap
        return rect
    }
}

func drawArtwork() {
    // The tile follows Apple's template: 824pt artwork centered on a 1024pt canvas.
    let artwork = NSRect(x: 100, y: 100, width: 824, height: 824)
    let tile = NSBezierPath(roundedRect: artwork, xRadius: 185, yRadius: 185)

    // Soft shadow under the tile.
    NSGraphicsContext.saveGraphicsState()
    let tileShadow = NSShadow()
    tileShadow.shadowOffset = NSSize(width: 0, height: -14)
    tileShadow.shadowBlurRadius = 28
    tileShadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    tileShadow.set()
    color(0x3E31B8).setFill()
    tile.fill()
    NSGraphicsContext.restoreGraphicsState()

    // Background gradient, light at the top and deep at the bottom.
    NSGradient(colors: [color(0x9A8BFF), color(0x4A3BD0)])?.draw(in: tile, angle: -90)

    // Gentle sheen across the top.
    NSGradient(starting: color(0xFFFFFF, alpha: 0.24), ending: color(0xFFFFFF, alpha: 0))?
        .draw(in: tile, angle: -90)

    // Thin inner edge so the tile reads clearly on dark backgrounds.
    NSGraphicsContext.saveGraphicsState()
    tile.addClip()
    tile.lineWidth = 6
    color(0xFFFFFF, alpha: 0.14).setStroke()
    tile.stroke()
    NSGraphicsContext.restoreGraphicsState()

    drawBars()
}

func drawBars() {
    let rects = barRects()
    let centerIndex = rects.count / 2

    // Shadow pass: gradients don't cast shadows reliably, so fill solid shapes first.
    NSGraphicsContext.saveGraphicsState()
    let barShadow = NSShadow()
    barShadow.shadowOffset = NSSize(width: 0, height: -8)
    barShadow.shadowBlurRadius = 20
    barShadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    barShadow.set()
    color(0xFFFFFF).setFill()
    for rect in rects {
        NSBezierPath(roundedRect: rect, xRadius: rect.width / 2, yRadius: rect.width / 2).fill()
    }
    NSGraphicsContext.restoreGraphicsState()

    // Color pass.
    for (index, rect) in rects.enumerated() {
        let bar = NSBezierPath(roundedRect: rect, xRadius: rect.width / 2, yRadius: rect.width / 2)
        let colors = index == centerIndex
            ? [color(0xFFD27A), color(0xFFAE42)]
            : [color(0xFFFFFF), color(0xDDD7FF)]
        NSGradient(colors: colors)?.draw(in: bar, angle: -90)
    }
}

func renderIcon(pixels: Int) -> Data? {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        return nil
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context

    let transform = NSAffineTransform()
    transform.scale(by: CGFloat(pixels) / 1024)
    transform.concat()
    drawArtwork()

    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])
}

guard CommandLine.arguments.count > 1 else {
    print("Usage: swift make-icon.swift <output .iconset directory>")
    exit(1)
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for size in sizes {
    guard let data = renderIcon(pixels: size.pixels) else {
        print("Failed to render \(size.name)")
        exit(1)
    }
    try data.write(to: outputDirectory.appendingPathComponent("\(size.name).png"))
}

print("Wrote \(sizes.count) icon images to \(outputDirectory.path)")
