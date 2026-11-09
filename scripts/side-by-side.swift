#!/usr/bin/env swift
// Cross-platform gallery: every golden name, iOS and Android next to each other.
// Each platform's gate only compares a platform with ITSELF, so differences between iOS and Android (an emoji bolt
// vs an SF Symbol, different line heights) are invisible to it. This page is for the design review of those.
//
// usage: swift scripts/side-by-side.swift <iosGoldens> <androidGoldens> <outDir>
import Foundation

let args = CommandLine.arguments
guard args.count == 4 else { print("usage: side-by-side <iosGoldens> <androidGoldens> <outDir>"); exit(2) }
let ios = URL(fileURLWithPath: args[1]).standardizedFileURL
let android = URL(fileURLWithPath: args[2]).standardizedFileURL
let out = URL(fileURLWithPath: args[3])
let fm = FileManager.default
try? fm.createDirectory(at: out, withIntermediateDirectories: true)

/// "<TestClass>/<test>.<variant>.png" → absolute path
func goldens(_ root: URL) -> [String: URL] {
    var result: [String: URL] = [:]
    let walker = fm.enumerator(at: root, includingPropertiesForKeys: nil)
    while let url = walker?.nextObject() as? URL {
        guard url.pathExtension == "png" else { continue }
        result[url.standardizedFileURL.path.replacingOccurrences(of: root.path + "/", with: "")] = url
    }
    return result
}

let left = goldens(ios), right = goldens(android)
let names = Set(left.keys).union(right.keys).sorted()
let outPath = out.standardizedFileURL.path

/// Relative path from the gallery to the image, so the page works when opened from disk.
func relative(_ url: URL) -> String {
    let from = outPath.split(separator: "/"), to = url.standardizedFileURL.path.split(separator: "/")
    var common = 0
    while common < min(from.count, to.count) && from[common] == to[common] { common += 1 }
    return (Array(repeating: "..", count: from.count - common) + to[common...].map(String.init)).joined(separator: "/")
}

func cell(_ url: URL?) -> String {
    url.map { "<img src=\"\(relative($0))\" loading=\"lazy\">" } ?? "<p class=\"missing\">no golden</p>"
}

var sections = ""
var currentGroup = ""
for name in names {
    let group = String(name.split(separator: "/").first ?? "")
    if group != currentGroup { sections += "<h2>\(group)</h2>\n"; currentGroup = group }
    sections += """
    <section><h3>\((name as NSString).lastPathComponent)</h3>
    <div class="pair"><figure><figcaption>iOS</figcaption>\(cell(left[name]))</figure>
    <figure><figcaption>Android</figcaption>\(cell(right[name]))</figure></div></section>

    """
}

let html = """
<!doctype html><meta charset="utf-8"><title>iOS vs Android goldens</title>
<style>body{font:14px -apple-system,sans-serif;margin:24px;background:#f4f4f5;color:#1a1a1a}
section{background:#fff;padding:12px;margin:0 0 16px;border-radius:8px}h3{font-size:13px;margin:0 0 8px}
.pair{display:flex;gap:16px;align-items:flex-start}figure{flex:1;margin:0}figcaption{color:#666;margin-bottom:4px}
img{max-width:100%;max-height:70vh;border:1px solid #ddd}.missing{color:#b00}</style>
<h1>iOS vs Android: \(names.count) screenshots</h1>
<p>Same fixture, same test name on both platforms. Use it to review <b>cross-platform</b> differences, which neither
platform's own gate can see.</p>
\(sections)
"""
try html.write(to: out.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
let onlyOne = names.filter { left[$0] == nil || right[$0] == nil }
print("side-by-side: \(names.count) screenshots, \(onlyOne.count) on one platform only → \(out.path)/index.html")
