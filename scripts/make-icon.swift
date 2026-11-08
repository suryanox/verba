#!/usr/bin/env swift
// Draws the Verba app icon at every size macOS needs and writes an .iconset folder.
//
// Usage: swift scripts/make-icon.swift <output .iconset directory>
//
// The artwork is a dark tile with a bold "V" (cream left arm, amber right arm that overlaps it)
// followed by an amber text cursor, so it reads as "V|": words being typed.
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

func makeShadow(offsetY: CGFloat, blur: CGFloat, alpha: CGFloat) -> NSShadow {
    let shadow = NSShadow()
    shadow.shadowOffset = NSSize(width: 0, height: -offsetY)
    shadow.shadowBlurRadius = blur
    shadow.shadowColor = NSColor.black.withAlphaComponent(alpha)
    return shadow
}

/// Draws a straight line with rounded ends and a soft shadow.
func strokeLine(from start: NSPoint, to end: NSPoint, width: CGFloat, fill: NSColor, shadow: NSShadow) {
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    let path = NSBezierPath()
    path.move(to: start)
    path.line(to: end)
    path.lineWidth = width
    path.lineCapStyle = .round
    fill.setStroke()
    path.stroke()
    NSGraphicsContext.restoreGraphicsState()
}

func drawTile() {
    // Apple's template: 824pt artwork centered on a 1024pt canvas.
    let artwork = NSRect(x: 100, y: 100, width: 824, height: 824)
    let tile = NSBezierPath(roundedRect: artwork, xRadius: 185, yRadius: 185)

    // Shadow pass: gradients don't cast shadows reliably, so fill a solid shape first.
    NSGraphicsContext.saveGraphicsState()
    makeShadow(offsetY: 14, blur: 28, alpha: 0.35).set()
    color(0x15151B).setFill()
    tile.fill()
    NSGraphicsContext.restoreGraphicsState()

    // Dark gradient, slightly lighter at the top.
    NSGradient(colors: [color(0x262731), color(0x0C0C11)])?.draw(in: tile, angle: -90)

    // Thin inner edge so the tile reads on dark backgrounds.
    NSGraphicsContext.saveGraphicsState()
    tile.addClip()
    tile.lineWidth = 6
    color(0xFFFFFF, alpha: 0.08).setStroke()
    tile.stroke()
    NSGraphicsContext.restoreGraphicsState()
}

func drawMark() {
    let strokeWidth: CGFloat = 112
    let apexX: CGFloat = 446
    let topY: CGFloat = 728
    let tipY: CGFloat = 296
    let halfSpan: CGFloat = 168

    // Cream left arm, then the amber right arm on top of it.
    strokeLine(
        from: NSPoint(x: apexX - halfSpan, y: topY),
        to: NSPoint(x: apexX, y: tipY),
        width: strokeWidth,
        fill: color(0xF6F1E7),
        shadow: makeShadow(offsetY: 10, blur: 20, alpha: 0.4)
    )
    strokeLine(
        from: NSPoint(x: apexX, y: tipY),
        to: NSPoint(x: apexX + halfSpan, y: topY),
        width: strokeWidth,
        fill: color(0xFFB347),
        shadow: makeShadow(offsetY: 6, blur: 18, alpha: 0.5)
    )

    // Text cursor.
    strokeLine(
        from: NSPoint(x: 790, y: tipY),
        to: NSPoint(x: 790, y: 554),
        width: 48,
        fill: color(0xFFB347),
        shadow: makeShadow(offsetY: 8, blur: 16, alpha: 0.4)
    )
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
    drawTile()
    drawMark()

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
