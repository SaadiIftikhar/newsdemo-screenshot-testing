#!/usr/bin/env swift
// Golden lint: fails if any reference image is blank (a single uniform colour) or tiny.
// A blank golden is worse than none: every later run is compared against nothing.
// (Found for real: right after the Robolectric SDK 37 upgrade, a few captures fired before the first frame.)
//
// usage: swift scripts/lint-goldens.swift <dir> [<dir> ...]
import CoreGraphics
import Foundation
import ImageIO

var problems: [String] = []
var checked = 0
for root in CommandLine.arguments.dropFirst() {
    let enumerator = FileManager.default.enumerator(atPath: root)
    while let path = enumerator?.nextObject() as? String {
        guard path.hasSuffix(".png") else { continue }
        let url = URL(fileURLWithPath: root).appendingPathComponent(path)
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(src, 0, nil) else { problems.append("unreadable: \(url.path)"); continue }
        checked += 1
        if image.width < 50 || image.height < 50 { problems.append("too small (\(image.width)×\(image.height)): \(url.path)"); continue }
        // Downsample to 64×64 and count distinct colours: a real screen has many, a blank frame has one.
        var pixels = [UInt8](repeating: 0, count: 64 * 64 * 4)
        let ctx = CGContext(data: &pixels, width: 64, height: 64, bitsPerComponent: 8, bytesPerRow: 64 * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.interpolationQuality = .none
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: 64, height: 64))
        var colours = Set<UInt32>()
        for i in stride(from: 0, to: pixels.count, by: 4) {
            colours.insert(UInt32(pixels[i]) << 16 | UInt32(pixels[i + 1]) << 8 | UInt32(pixels[i + 2]))
        }
        if colours.count < 3 { problems.append("blank (\(colours.count) colour/s): \(url.path)") }
    }
}
// Cross-platform parity: iOS and Android must have exactly the same golden names (same tests, same variants).
// A test added, renamed or removed on one platform only fails here instead of drifting silently.
let roots = Array(CommandLine.arguments.dropFirst())
if roots.count == 2 {
    func names(_ root: String) -> Set<String> {
        Set((FileManager.default.enumerator(atPath: root)?.allObjects as? [String] ?? []).filter { $0.hasSuffix(".png") })
    }
    let (ios, android) = (names(roots[0]), names(roots[1]))
    ios.subtracting(android).sorted().forEach { problems.append("only on iOS: \($0)") }
    android.subtracting(ios).sorted().forEach { problems.append("only on Android: \($0)") }
}
print("lint-goldens: checked \(checked) image(s)\(roots.count == 2 ? ", parity iOS ↔ Android" : "")")
problems.forEach { print("  ✗ \($0)") }
exit(problems.isEmpty ? 0 : 1)
