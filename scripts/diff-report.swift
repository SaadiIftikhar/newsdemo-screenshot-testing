#!/usr/bin/env swift
// Builds a review artifact for failed snapshots: for every failed image, a composite
//   [ golden | actual | difference: magenta = only in golden, blue = only in new, orange = colour changed ]
// plus an index.html gallery. CI uploads the folder; reviewers (dev, QA, design) open index.html.
//
// usage: swift scripts/diff-report.swift <goldensRoot> <failuresRoot> <outDir>
import CoreGraphics
import CoreText
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

// Diff colours: blue and magenta stay distinguishable for the common colour-vision deficiencies.
let removedColour: (UInt8, UInt8, UInt8) = (230, 0, 160)    // only in the golden: magenta
let addedColour: (UInt8, UInt8, UInt8) = (20, 110, 255)     // only in the new picture: blue
let recolouredColour: (UInt8, UInt8, UInt8) = (255, 150, 0) // in both, colour changed: orange
let ink: (UInt8, UInt8, UInt8) = (27, 31, 59)

/// Most common colour of each row (colours bucketed to 4 bits per channel): the background a row's content sits on.
func rowBackgrounds(_ px: [UInt8], width: Int, height: Int) -> [(Int, Int, Int)] {
    var counts = [Int](repeating: 0, count: 4096), touched: [Int] = []
    var result: [(Int, Int, Int)] = []
    result.reserveCapacity(height)
    for y in 0..<height {
        var best = 0, bestCount = -1
        for x in 0..<width {
            let i = (y * width + x) * 4
            let key = Int(px[i] >> 4) << 8 | Int(px[i + 1] >> 4) << 4 | Int(px[i + 2] >> 4)
            if counts[key] == 0 { touched.append(key) }
            counts[key] += 1
            if counts[key] > bestCount { bestCount = counts[key]; best = key }
        }
        result.append(((best >> 8) * 16 + 8, ((best >> 4) & 15) * 16 + 8, (best & 15) * 16 + 8))
        for key in touched { counts[key] = 0 }
        touched.removeAll(keepingCapacity: true)
    }
    return result
}

func distance(_ px: [UInt8], _ i: Int, _ bg: (Int, Int, Int)) -> Int {
    abs(Int(px[i]) - bg.0) + abs(Int(px[i + 1]) - bg.1) + abs(Int(px[i + 2]) - bg.2)
}

/// Draws one line of text made of coloured runs (CoreText, no AppKit).
func label(_ ctx: CGContext, _ runs: [(String, (UInt8, UInt8, UInt8))], x: CGFloat, y: CGFloat, size: CGFloat) {
    let font = CTFontCreateWithName("Helvetica-Bold" as CFString, size, nil)
    var cursor = x
    for (text, c) in runs {
        let colour = CGColor(red: CGFloat(c.0) / 255, green: CGFloat(c.1) / 255, blue: CGFloat(c.2) / 255, alpha: 1)
        let attrs = [kCTFontAttributeName: font, kCTForegroundColorAttributeName: colour] as CFDictionary
        let line = CTLineCreateWithAttributedString(CFAttributedStringCreate(nil, text as CFString, attrs)!)
        ctx.textPosition = CGPoint(x: cursor, y: y)
        CTLineDraw(line, ctx)
        cursor += CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
    }
}

struct Row {
    let name: String; let file: String; let changed: Int; let subtle: Int; let total: Int; let sizeNote: String
    /// Triage hint for the reviewer, NOT an auto-approval: every failed snapshot still needs a human decision.
    var severity: String {
        if !sizeNote.isEmpty { return "layout" }           // the screen got taller/shorter: something moved
        if changed > 0 { return "visible" }                // pixels a person can see changed
        return "subtle"                                    // colour/anti-aliasing shift only (check design tokens)
    }
}
var rows: [Row] = []
var missingReferences: [String] = []

/// Golden for a failure image: the failures folder mirrors the golden folder (<TestClass>/<test>.<variant>.png).
/// No golden at that path means a NEW screenshot, which is reported, never silently skipped.
func reference(for relative: String) -> URL? {
    let direct = goldens.appendingPathComponent(relative)
    return fm.fileExists(atPath: direct.path) ? direct : nil
}

let enumerator = fm.enumerator(at: failures, includingPropertiesForKeys: nil)
while let url = enumerator?.nextObject() as? URL {
    guard url.pathExtension == "png" else { continue }
    var relative = url.path.replacingOccurrences(of: failures.path + "/", with: "")
    guard let actual = load(url) else { continue }
    guard let refURL = reference(for: relative), let reference = load(refURL) else {
        missingReferences.append(relative) // a NEW screenshot with no golden: must be reviewed, never silently skipped
        continue
    }
    relative = refURL.path.replacingOccurrences(of: goldens.path + "/", with: "")

    let w = max(actual.width, reference.width), h = max(actual.height, reference.height)
    let a = rgba(actual, width: w, height: h), r = rgba(reference, width: w, height: h)
    // Which picture does a changed pixel belong to? A pixel is "content" in a picture when it stands out from
    // that row's background (the row's most common colour). Then a changed pixel is:
    //   only content in the golden → magenta (removed, or moved away from here)
    //   only content in the new picture → blue (added, or moved to here)
    //   content in both, or a slight shift → orange (colour changed)
    // so a moved headline shows as magenta (old place) next to blue (new place), not as one magenta blur.
    let rowBackgroundA = rowBackgrounds(a, width: w, height: h), rowBackgroundR = rowBackgrounds(r, width: w, height: h)
    var diff = [UInt8](repeating: 255, count: w * h * 4)
    var changed = 0, subtle = 0
    for i in stride(from: 0, to: a.count, by: 4) {
        let delta = abs(Int(a[i]) - Int(r[i])) + abs(Int(a[i + 1]) - Int(r[i + 1])) + abs(Int(a[i + 2]) - Int(r[i + 2]))
        if delta > 24 {
            changed += 1
            let row = i / 4 / w
            let inGolden = distance(r, i, rowBackgroundR[row]) > 60, inNew = distance(a, i, rowBackgroundA[row]) > 60
            let colour: (UInt8, UInt8, UInt8) = inGolden && !inNew ? removedColour : (inNew && !inGolden ? addedColour : recolouredColour)
            diff[i] = colour.0; diff[i + 1] = colour.1; diff[i + 2] = colour.2
        } else if delta > 0 {
            subtle += 1
            diff[i] = recolouredColour.0; diff[i + 1] = recolouredColour.1; diff[i + 2] = recolouredColour.2
            // Shown on purpose: the test can fail on a shift the eye barely sees; the report must not say "0 px".
        } else {
            let gray = UInt8(200 + Int(r[i]) / 5 > 255 ? 255 : 200 + Int(r[i]) / 5) // faded reference for context
            diff[i] = gray; diff[i + 1] = gray; diff[i + 2] = gray
        }
    }

    // Composite: a label band on top (what each panel is, plus the colour key), then golden | new | difference.
    let gap = 24, header = max(72, w / 11)
    let canvasW = w * 3 + gap * 2, canvasH = h + header
    let ctx = CGContext(data: nil, width: canvasW, height: canvasH, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setFillColor(CGColor(gray: 0.85, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: canvasW, height: canvasH))
    ctx.setFillColor(CGColor(gray: 1, alpha: 1)); ctx.fill(CGRect(x: 0, y: h, width: canvasW, height: header))
    ctx.draw(reference, in: CGRect(x: 0, y: h - reference.height, width: reference.width, height: reference.height))
    ctx.draw(actual, in: CGRect(x: w + gap, y: h - actual.height, width: actual.width, height: actual.height))
    ctx.draw(image(from: &diff, width: w, height: h), in: CGRect(x: (w + gap) * 2, y: 0, width: w, height: h))
    let size = CGFloat(header) * 0.36, base = CGFloat(h) + CGFloat(header) * 0.36
    label(ctx, [("Golden (approved)", ink)], x: CGFloat(header) * 0.3, y: base, size: size)
    label(ctx, [("New (this change)", ink)], x: CGFloat(w + gap) + CGFloat(header) * 0.3, y: base, size: size)
    label(ctx, [("■ only in golden  ", removedColour), ("■ only in new  ", addedColour), ("■ colour changed", recolouredColour)],
          x: CGFloat((w + gap) * 2) + CGFloat(header) * 0.3, y: base, size: size * 0.8)

    let name = relative.replacingOccurrences(of: "/", with: "__")
    let dest = CGImageDestinationCreateWithURL(out.appendingPathComponent(name) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
    let sizeNote = (actual.width, actual.height) == (reference.width, reference.height)
        ? "" : " · size changed \(reference.width)×\(reference.height) → \(actual.width)×\(actual.height)px"
    rows.append(Row(name: relative, file: name, changed: changed, subtle: subtle, total: w * h, sizeNote: sizeNote))
}

rows.sort { $0.name < $1.name }
let items = rows.map { row in
    let pct = String(format: "%.2f", Double(row.changed) / Double(row.total) * 100)
    return """
    <section><h2>\(row.name) <small>[\(row.severity)]</small></h2><p>\(row.changed) px clearly changed (\(pct)%), \(row.subtle) px subtly changed\(row.sizeNote)</p>
        <img src="\(row.file)" loading="lazy"></section>
    """
}.joined(separator: "\n")
let html = """
<!doctype html><meta charset="utf-8"><title>Snapshot diffs</title>
<style>body{font:14px -apple-system,sans-serif;margin:24px;background:#f4f4f5}section{background:#fff;padding:16px;margin:0 0 24px;border-radius:8px}
img{max-width:100%;max-height:80vh}h2{font-size:15px;margin:0 0 4px}.legend{display:flex;gap:24px;color:#666}.legend span{flex:1}</style>
<h1>\(rows.count) snapshot(s) changed</h1>
\(missingReferences.isEmpty ? "" : "<p><b>No golden yet (new tests):</b> " + missingReferences.joined(separator: ", ") + "</p>")
<p>Each picture: golden | new | difference. In the difference, <b style="color:#e600a0">magenta</b> = only in the golden (removed or moved away), <b style="color:#146eff">blue</b> = only in the new picture (added or moved here), <b style="color:#ff9600">orange</b> = colour changed.</p>
<p>Unintended → fix the code. Intended → add the <code>record-snapshots</code> label; a design/QA code-owner approves the new goldens.</p>
\(items)
"""
try html.write(to: out.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)

// Markdown summary for the CI job summary and the sticky PR comment: a reviewer sees WHAT kind of change it is
// before opening a single image.
let counts = Dictionary(grouping: rows, by: \.severity).mapValues(\.count)
var md = "| Snapshot | Kind | Clearly changed | Subtle |\n|---|---|---|---|\n"
for row in rows {
    md += "| `\(row.name)` | \(row.severity) | \(row.changed) px | \(row.subtle) px |\n"
}
for name in missingReferences { md += "| `\(name)` | new (no golden) | – | – |\n" }
let header = "**\(rows.count) changed** (layout: \(counts["layout"] ?? 0), visible: \(counts["visible"] ?? 0), "
    + "subtle: \(counts["subtle"] ?? 0)), **\(missingReferences.count) new**\n\n"
try (header + md).write(to: out.appendingPathComponent("summary.md"), atomically: true, encoding: .utf8)
print("diff report: \(rows.count) failure(s), \(missingReferences.count) without golden → \(out.path)/index.html")
