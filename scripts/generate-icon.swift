#!/usr/bin/env swift
import AppKit

let sizes: [(Int, String)] = [
    (1024, "icon_512x512@2x"),
    (512,  "icon_512x512"),
    (512,  "icon_256x256@2x"),
    (256,  "icon_256x256"),
    (256,  "icon_128x128@2x"),
    (128,  "icon_128x128"),
    (64,   "icon_32x32@2x"),
    (32,   "icon_32x32"),
    (32,   "icon_16x16@2x"),
    (16,   "icon_16x16"),
]

func drawIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    // Background rounded rect
    let cornerRadius = s * 0.22
    let bgRect = CGRect(x: 0, y: 0, width: s, height: s)
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Gradient background: deep indigo to violet
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradientColors = [
        CGColor(red: 0.25, green: 0.15, blue: 0.70, alpha: 1.0),
        CGColor(red: 0.55, green: 0.25, blue: 0.85, alpha: 1.0),
        CGColor(red: 0.40, green: 0.20, blue: 0.90, alpha: 1.0),
    ] as CFArray
    let locations: [CGFloat] = [0.0, 0.6, 1.0]

    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: locations) {
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: s),
                               end: CGPoint(x: s, y: 0),
                               options: [])
    }
    ctx.restoreGState()

    // Subtle inner glow
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    let glowCenter = CGPoint(x: s * 0.35, y: s * 0.65)
    if let glowGradient = CGGradient(colorsSpace: colorSpace,
        colors: [
            CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.12),
            CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0),
        ] as CFArray,
        locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(glowGradient,
                                startCenter: glowCenter, startRadius: 0,
                                endCenter: glowCenter, endRadius: s * 0.6,
                                options: [])
    }
    ctx.restoreGState()

    // Clipboard body
    let clipW = s * 0.48
    let clipH = s * 0.56
    let clipX = s * 0.26
    let clipY = s * 0.14
    let clipRect = CGRect(x: clipX, y: clipY, width: clipW, height: clipH)
    let clipPath = CGPath(roundedRect: clipRect, cornerWidth: s * 0.04, cornerHeight: s * 0.04, transform: nil)

    ctx.saveGState()
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.92))
    ctx.addPath(clipPath)
    ctx.fillPath()
    ctx.restoreGState()

    // Clipboard clip (top tab)
    let tabW = s * 0.20
    let tabH = s * 0.08
    let tabX = s * 0.40
    let tabY = clipY + clipH - s * 0.04
    let tabRect = CGRect(x: tabX, y: tabY, width: tabW, height: tabH)
    let tabPath = CGPath(roundedRect: tabRect, cornerWidth: s * 0.025, cornerHeight: s * 0.025, transform: nil)

    ctx.saveGState()
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.92))
    ctx.addPath(tabPath)
    ctx.fillPath()
    ctx.restoreGState()

    // Text lines on clipboard
    let lineColor = CGColor(red: 0.30, green: 0.20, blue: 0.65, alpha: 0.25)
    ctx.setFillColor(lineColor)
    let lineH = s * 0.025
    let lineSpacing = s * 0.055
    let lineX = clipX + s * 0.06
    let lineWidths: [CGFloat] = [0.32, 0.28, 0.24, 0.30, 0.18]
    for (i, w) in lineWidths.enumerated() {
        let ly = clipY + clipH - s * 0.18 - CGFloat(i) * lineSpacing
        let lineRect = CGRect(x: lineX, y: ly, width: s * w, height: lineH)
        let linePath = CGPath(roundedRect: lineRect, cornerWidth: lineH / 2, cornerHeight: lineH / 2, transform: nil)
        ctx.addPath(linePath)
        ctx.fillPath()
    }

    // Sparkles (3 stars)
    drawSparkle(ctx: ctx, center: CGPoint(x: s * 0.72, y: s * 0.72), size: s * 0.12, alpha: 1.0)
    drawSparkle(ctx: ctx, center: CGPoint(x: s * 0.82, y: s * 0.55), size: s * 0.07, alpha: 0.75)
    drawSparkle(ctx: ctx, center: CGPoint(x: s * 0.62, y: s * 0.82), size: s * 0.05, alpha: 0.6)

    image.unlockFocus()
    return image
}

func drawSparkle(ctx: CGContext, center: CGPoint, size: CGFloat, alpha: CGFloat) {
    ctx.saveGState()
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: alpha))

    let path = CGMutablePath()
    // 4-pointed star
    let outer = size
    let inner = size * 0.28

    for i in 0..<8 {
        let angle = CGFloat(i) * .pi / 4 - .pi / 2
        let r = i % 2 == 0 ? outer : inner
        let x = center.x + cos(angle) * r
        let y = center.y + sin(angle) * r
        if i == 0 {
            path.move(to: CGPoint(x: x, y: y))
        } else {
            path.addLine(to: CGPoint(x: x, y: y))
        }
    }
    path.closeSubpath()
    ctx.addPath(path)
    ctx.fillPath()
    ctx.restoreGState()
}

// Main
let iconsetDir = "ClipAI/Assets.xcassets/AppIcon.appiconset"
let fm = FileManager.default

// Create directory
try? fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

// Generate icons
for (size, name) in sizes {
    let image = drawIcon(size: size)
    guard let tiffData = image.tiffRepresentation,
          let bitmapRep = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("Failed to generate \(name)")
        continue
    }
    let path = "\(iconsetDir)/\(name).png"
    try! pngData.write(to: URL(fileURLWithPath: path))
    print("Generated \(name).png (\(size)x\(size))")
}

// Generate Contents.json
let contentsJSON = """
{
  "images" : [
    { "filename" : "icon_16x16.png",      "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "filename" : "icon_16x16@2x.png",   "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "filename" : "icon_32x32.png",       "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "filename" : "icon_32x32@2x.png",    "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "filename" : "icon_128x128.png",     "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "filename" : "icon_128x128@2x.png",  "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "filename" : "icon_256x256.png",     "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "filename" : "icon_256x256@2x.png",  "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "filename" : "icon_512x512.png",     "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "filename" : "icon_512x512@2x.png",  "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
"""
try! contentsJSON.write(toFile: "\(iconsetDir)/Contents.json", atomically: true, encoding: .utf8)
print("Generated Contents.json")
print("Done! Icon assets created at \(iconsetDir)")
