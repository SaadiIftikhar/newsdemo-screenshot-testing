#!/usr/bin/env swift
// Builds a review artifact for failed snapshots: for every failed image, a composite
//   [ reference | actual | changed pixels in magenta ]
// plus an index.html gallery. CI uploads the folder; reviewers (dev, QA, design) open index.html.
//
// usage: swift scripts/diff-report.swift <goldensRoot> <failuresRoot> <outDir>
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count == 4 else { print("usage: diff-report <goldensRoot> <failuresRoot> <outDir>"); exit(2) }
let goldens = URL(fileURLWithPath: args[1]), failures = URL(fileURLWithPath: args[2]), out = URL(fileURLWithPath: args[3])
let fm = FileManager.default
try? fm.createDirectory(at: out, withIntermediateDirectories: true)

func load(_ url: URL) -> CGImage? {
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(src, 0, nil)
}

func rgba(_ image: CGImage, width: Int, height: Int) -> [UInt8] {
    var buffer = [UInt8](repeating: 255, count: width * height * 4)
    let ctx = CGContext(data: &buffer, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    // Top-align both images so a height change shows up as a shift, not a rescale.
    ctx.draw(image, in: CGRect(x: 0, y: height - image.height, width: image.width, height: image.height))
    return buffer
}

func image(from buffer: inout [UInt8], width: Int, height: Int) -> CGImage {
    CGContext(data: &buffer, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
              space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!.makeImage()!
}

struct Row { let name: String; let file: String; let changed: Int; let total: Int; let sizeNote: String }
var rows: [Row] = []

let enumerator = fm.enumerator(at: failures, includingPropertiesForKeys: nil)
while let url = enumerator?.nextObject() as? URL {
    guard url.pathExtension == "png" else { continue }
    let relative = url.path.replacingOccurrences(of: failures.path + "/", with: "")
    guard let actual = load(url), let reference = load(goldens.appendingPathComponent(relative)) else { continue }

    let w = max(actual.width, reference.width), h = max(actual.height, reference.height)
    let a = rgba(actual, width: w, height: h), r = rgba(reference, width: w, height: h)
    var diff = [UInt8](repeating: 255, count: w * h * 4)
    var changed = 0
    for i in stride(from: 0, to: a.count, by: 4) {
        let delta = abs(Int(a[i]) - Int(r[i])) + abs(Int(a[i + 1]) - Int(r[i + 1])) + abs(Int(a[i + 2]) - Int(r[i + 2]))
        if delta > 24 {
            changed += 1
            diff[i] = 255; diff[i + 1] = 0; diff[i + 2] = 200
        } else {
            let gray = UInt8(200 + Int(r[i]) / 5 > 255 ? 255 : 200 + Int(r[i]) / 5) // faded reference for context
            diff[i] = gray; diff[i + 1] = gray; diff[i + 2] = gray
        }
    }

    let gap = 24
    let canvasW = w * 3 + gap * 2
    let ctx = CGContext(data: nil, width: canvasW, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setFillColor(CGColor(gray: 0.85, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: canvasW, height: h))
    ctx.draw(reference, in: CGRect(x: 0, y: h - reference.height, width: reference.width, height: reference.height))
    ctx.draw(actual, in: CGRect(x: w + gap, y: h - actual.height, width: actual.width, height: actual.height))
    ctx.draw(image(from: &diff, width: w, height: h), in: CGRect(x: (w + gap) * 2, y: 0, width: w, height: h))

    let name = relative.replacingOccurrences(of: "/", with: "__")
    let dest = CGImageDestinationCreateWithURL(out.appendingPathComponent(name) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
    let sizeNote = (actual.width, actual.height) == (reference.width, reference.height)
        ? "" : " · size changed \(reference.width)×\(reference.height) → \(actual.width)×\(actual.height)px"
    rows.append(Row(name: relative, file: name, changed: changed, total: w * h, sizeNote: sizeNote))
}

rows.sort { $0.name < $1.name }
let items = rows.map { row in
    let pct = String(format: "%.2f", Double(row.changed) / Double(row.total) * 100)
    return """
    <section><h2>\(row.name)</h2><p>\(row.changed) px changed (\(pct)%)\(row.sizeNote)</p>
    <p class="legend"><span>reference (golden)</span><span>actual (this PR)</span><span>changed pixels</span></p>
    <img src="\(row.file)" loading="lazy"></section>
    """
}.joined(separator: "\n")
let html = """
<!doctype html><meta charset="utf-8"><title>Snapshot diffs</title>
<style>body{font:14px -apple-system,sans-serif;margin:24px;background:#f4f4f5}section{background:#fff;padding:16px;margin:0 0 24px;border-radius:8px}
img{max-width:100%;max-height:80vh}h2{font-size:15px;margin:0 0 4px}.legend{display:flex;gap:24px;color:#666}.legend span{flex:1}</style>
<h1>\(rows.count) snapshot(s) changed</h1>
<p>Unintended → fix the code. Intended → add the <code>record-snapshots</code> label; a design/QA code-owner approves the new goldens.</p>
\(items)
"""
try html.write(to: out.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
print("diff report: \(rows.count) failure(s) → \(out.path)/index.html")
