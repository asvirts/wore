#!/usr/bin/env swift
import AppKit
import CoreGraphics
import Foundation

func renderIcon(pixelSize: Int) -> Data {
    let size = CGFloat(pixelSize)
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    let ctx = CGContext(
        data: nil,
        width: pixelSize,
        height: pixelSize,
        bitsPerComponent: 8,
        bytesPerRow: pixelSize * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    )!

    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

    let bounds = CGRect(x: 0, y: 0, width: size, height: size)
    let colors = [
        CGColor(srgbRed: 0.86, green: 0.55, blue: 0.42, alpha: 1),
        CGColor(srgbRed: 0.45, green: 0.22, blue: 0.20, alpha: 1),
    ] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: bounds.midX, y: bounds.maxY),
        end: CGPoint(x: bounds.midX, y: bounds.minY),
        options: []
    )

    ctx.setStrokeColor(CGColor(srgbRed: 0.99, green: 0.96, blue: 0.93, alpha: 1))
    ctx.setLineWidth(size * 0.042)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    let midX = bounds.midX
    let hookCenter = CGPoint(x: midX + size * 0.045, y: bounds.minY + size * 0.74)
    let hookRadius = size * 0.055
    ctx.addArc(
        center: hookCenter,
        radius: hookRadius,
        startAngle: .pi * 1.05,
        endAngle: .pi * 1.95,
        clockwise: false
    )
    ctx.move(to: CGPoint(x: midX, y: hookCenter.y - hookRadius * 0.15))
    ctx.addLine(to: CGPoint(x: midX, y: bounds.minY + size * 0.58))

    let neck = CGPoint(x: midX, y: bounds.minY + size * 0.56)
    let left = CGPoint(x: bounds.minX + size * 0.20, y: bounds.minY + size * 0.46)
    let right = CGPoint(x: bounds.maxX - size * 0.20, y: bounds.minY + size * 0.46)
    let bottom = CGPoint(x: midX, y: bounds.minY + size * 0.22)
    ctx.move(to: left)
    ctx.addLine(to: neck)
    ctx.addLine(to: right)
    ctx.move(to: left)
    ctx.addLine(to: bottom)
    ctx.addLine(to: right)
    ctx.strokePath()

    let cgImage = ctx.makeImage()!
    let rep = NSBitmapImageRep(cgImage: cgImage)
    return rep.representation(using: .png, properties: [:])!
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let dir = root.appendingPathComponent("Wore/Resources/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
let png = renderIcon(pixelSize: 1024)
try png.write(to: dir.appendingPathComponent("AppIcon-1024.png"))

let contents: [String: Any] = [
    "images": [
        [
            "filename": "AppIcon-1024.png",
            "idiom": "universal",
            "platform": "ios",
            "size": "1024x1024",
        ],
    ],
    "info": ["author": "xcode", "version": 1],
]
let json = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try json.write(to: dir.appendingPathComponent("Contents.json"))
print("Generated AppIcon.appiconset")
