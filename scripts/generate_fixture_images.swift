#!/usr/bin/env swift
// Generates the deterministic placeholder images used by fixtures (stand-ins for CDN images).
// Run once: swift scripts/generate_fixture_images.swift  — output is committed.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let width = 640, height = 360
let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "fixtures/images")

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

func render(_ name: String, _ top: UInt32, _ bottom: UInt32, shapes: (CGContext) -> Void) {
    let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                              colors: [rgb(top), rgb(bottom)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: height), end: CGPoint(x: width, y: 0), options: [])
    shapes(ctx)
    let url = out.appendingPathComponent(name)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(url.path)")
}

// Politics: a stylised parliament dome.
render("politics.png", 0x1F3A5F, 0x4A7BA7) { ctx in
    ctx.setFillColor(CGColor(gray: 1, alpha: 0.85))
    ctx.fill(CGRect(x: 170, y: 80, width: 300, height: 30))
    for i in 0..<6 { ctx.fill(CGRect(x: 185 + i * 52, y: 110, width: 22, height: 110)) }
    ctx.fill(CGRect(x: 150, y: 220, width: 340, height: 30))
    ctx.addEllipse(in: CGRect(x: 250, y: 20, width: 140, height: 120)); ctx.fillPath()
}
// Economy: a rising bar chart.
render("economy.png", 0x0B6E4F, 0x58B09C) { ctx in
    ctx.setFillColor(CGColor(gray: 1, alpha: 0.85))
    for (i, h) in [60, 110, 90, 160, 210, 250].enumerated() {
        ctx.fill(CGRect(x: 110 + i * 75, y: 50, width: 45, height: h))
    }
}
// Sport: a pitch with a ball.
render("sport.png", 0x2D6A1F, 0x6FBF4A) { ctx in
    ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.8)); ctx.setLineWidth(6)
    ctx.stroke(CGRect(x: 40, y: 30, width: 560, height: 300))
    ctx.move(to: CGPoint(x: 320, y: 30)); ctx.addLine(to: CGPoint(x: 320, y: 330)); ctx.strokePath()
    ctx.strokeEllipse(in: CGRect(x: 260, y: 120, width: 120, height: 120))
    ctx.setFillColor(CGColor(gray: 1, alpha: 1))
    ctx.fillEllipse(in: CGRect(x: 440, y: 150, width: 44, height: 44))
}
