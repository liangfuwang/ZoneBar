#!/usr/bin/env swift
// Generates Resources/AppIcon.icns. Usage: swift scripts/make-icon.swift
import AppKit

func render(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    let s = CGFloat(pixels)

    // macOS icon grid: artwork occupies ~82% of the canvas, centered.
    let inset = s * 0.09
    let body = CGRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    let radius = body.width * 0.225
    let bodyPath = CGPath(roundedRect: body, cornerWidth: radius, cornerHeight: radius, transform: nil)

    // Soft drop shadow + gradient background.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.012), blur: s * 0.025,
                  color: NSColor.black.withAlphaComponent(0.35).cgColor)
    ctx.addPath(bodyPath)
    ctx.setFillColor(NSColor(red: 0.10, green: 0.30, blue: 0.75, alpha: 1).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(bodyPath)
    ctx.clip()
    let grad = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [NSColor(red: 0.30, green: 0.62, blue: 1.00, alpha: 1).cgColor,
                 NSColor(red: 0.10, green: 0.25, blue: 0.70, alpha: 1).cgColor] as CFArray,
        locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: s / 2, y: body.maxY),
                           end: CGPoint(x: s / 2, y: body.minY), options: [])
    ctx.restoreGState()

    // Clock face.
    let c = CGPoint(x: s / 2, y: s / 2)
    let faceR = body.width * 0.36
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fillEllipse(in: CGRect(x: c.x - faceR, y: c.y - faceR, width: faceR * 2, height: faceR * 2))

    // Hour ticks.
    ctx.setStrokeColor(NSColor(white: 0.55, alpha: 1).cgColor)
    ctx.setLineCap(.round)
    for i in 0..<12 {
        let a = CGFloat(i) * .pi / 6
        let major = i % 3 == 0
        let r1 = faceR * (major ? 0.80 : 0.86), r2 = faceR * 0.93
        ctx.setLineWidth(s * (major ? 0.012 : 0.008))
        ctx.move(to: CGPoint(x: c.x + sin(a) * r1, y: c.y + cos(a) * r1))
        ctx.addLine(to: CGPoint(x: c.x + sin(a) * r2, y: c.y + cos(a) * r2))
        ctx.strokePath()
    }

    // Hands pointing to 10:10.
    func hand(angle: CGFloat, length: CGFloat, width: CGFloat, color: NSColor) {
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(width)
        ctx.move(to: c)
        ctx.addLine(to: CGPoint(x: c.x + sin(angle) * length, y: c.y + cos(angle) * length))
        ctx.strokePath()
    }
    let navy = NSColor(red: 0.08, green: 0.18, blue: 0.45, alpha: 1)
    hand(angle: -.pi / 3 - .pi / 36, length: faceR * 0.50, width: s * 0.034, color: navy)      // hour
    hand(angle: .pi / 3, length: faceR * 0.72, width: s * 0.026, color: navy)                  // minute
    ctx.setFillColor(navy.cgColor)
    let dot = s * 0.022
    ctx.fillEllipse(in: CGRect(x: c.x - dot, y: c.y - dot, width: dot * 2, height: dot * 2))

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent()
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

for base in [16, 32, 128, 256, 512] {
    try render(pixels: base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try render(pixels: base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}

let out = root.appendingPathComponent("Resources")
try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
let icns = out.appendingPathComponent("AppIcon.icns")
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset.path, "-o", icns.path]
try p.run()
p.waitUntilExit()
try? FileManager.default.removeItem(at: iconset)
print(p.terminationStatus == 0 ? "Wrote \(icns.path)" : "iconutil failed")
