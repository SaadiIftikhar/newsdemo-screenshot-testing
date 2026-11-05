#!/usr/bin/env swift
// Prints an HTML file to a paginated A4 PDF with the system WebKit (no browser needed).
// usage: swift scripts/html2pdf.swift in.html out.pdf
import AppKit
import WebKit

let input = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])

final class Printer: NSObject, WKNavigationDelegate {
    let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 595, height: 842))
    override init() {
        super.init()
        webView.navigationDelegate = self
        webView.loadFileURL(input, allowingReadAccessTo: input.deletingLastPathComponent())
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let info = NSPrintInfo()
        info.paperSize = NSSize(width: 595.28, height: 841.89) // A4 in points
        info.topMargin = 30; info.bottomMargin = 30; info.leftMargin = 42; info.rightMargin = 42
        info.horizontalPagination = .fit
        info.verticalPagination = .automatic
        info.jobDisposition = .save
        info.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = output
        let op = webView.printOperation(with: info)
        op.showsPrintPanel = false
        op.showsProgressPanel = false
        op.view?.frame = webView.bounds
        op.runModal(for: NSWindow(), delegate: self, didRun: #selector(done), contextInfo: nil)
    }
    @objc func done() { print("wrote \(output.path)"); exit(0) }
}

let app = NSApplication.shared
let printer = Printer()
DispatchQueue.main.asyncAfter(deadline: .now() + 60) { print("timeout"); exit(1) }
app.run()
