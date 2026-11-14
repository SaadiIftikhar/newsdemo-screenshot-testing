#!/usr/bin/env swift
// Gallery: every golden on one page, grouped by test class, with light/dark/large-text variants next to each other.
// For design review: "what do all approved states look like right now?" without opening 89 files.
//
// usage: swift scripts/gallery.swift <goldensRoot> <outDir>
import Foundation

let args = CommandLine.arguments
guard args.count == 3 else { print("usage: gallery <goldensRoot> <outDir>"); exit(2) }
let root = URL(fileURLWithPath: args[1]).standardizedFileURL
let out = URL(fileURLWithPath: args[2])
let fm = FileManager.default
try? fm.createDirectory(at: out, withIntermediateDirectories: true)

var files: [String] = []
let walker = fm.enumerator(at: root, includingPropertiesForKeys: nil)
while let url = walker?.nextObject() as? URL {
    guard url.pathExtension == "png" else { continue }
    files.append(url.standardizedFileURL.path.replacingOccurrences(of: root.path + "/", with: ""))
}
files.sort()

/// Relative path from the gallery page to an image, so the page works when opened from disk.
func relative(_ file: String) -> String {
    let from = out.standardizedFileURL.path.split(separator: "/"), to = (root.path + "/" + file).split(separator: "/")
    var common = 0
    while common < min(from.count, to.count) && from[common] == to[common] { common += 1 }
    return (Array(repeating: "..", count: from.count - common) + to[common...].map(String.init)).joined(separator: "/")
}

// "TestClass/test_name.variant.png" → group by class, then by test, variants side by side.
var html = ""
var currentClass = "", currentTest = ""
for file in files {
    let parts = file.split(separator: "/")
    let cls = String(parts.first ?? ""), name = String(parts.last ?? "")
    let test = String(name.split(separator: ".").first ?? "")
    let variant = name.split(separator: ".").dropFirst().dropLast().joined(separator: ".")
    if cls != currentClass { if !currentTest.isEmpty { html += "</div></section>\n" }; html += "<h2>\(cls)</h2>\n"; currentClass = cls; currentTest = "" }
    if test != currentTest {
        if !currentTest.isEmpty { html += "</div></section>\n" }
        html += "<section><h3>\(test)</h3><div class=\"row\">\n"; currentTest = test
    }
    html += "<figure><figcaption>\(variant)</figcaption><img src=\"\(relative(file))\" loading=\"lazy\"></figure>\n"
}
if !currentTest.isEmpty { html += "</div></section>\n" }

let page = """
<!doctype html><meta charset="utf-8"><title>Golden gallery</title>
<style>body{font:14px -apple-system,sans-serif;margin:24px;background:#f4f4f5;color:#1a1a1a}
section{background:#fff;padding:12px;margin:0 0 16px;border-radius:8px}h3{font-size:13px;margin:0 0 8px}
.row{display:flex;gap:16px;align-items:flex-start;flex-wrap:wrap}figure{margin:0;max-width:300px}
figcaption{color:#666;margin-bottom:4px}img{max-width:300px;max-height:70vh;border:1px solid #ddd}</style>
<h1>All approved screenshots (\(files.count))</h1>
<p>Every golden the tests compare against, grouped by test. Variants (light, dark, largest text) side by side.</p>
\(html)
"""
try page.write(to: out.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
print("gallery: \(files.count) goldens → \(out.path)/index.html")
