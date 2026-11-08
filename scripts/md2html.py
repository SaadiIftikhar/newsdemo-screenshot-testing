#!/usr/bin/env python3
"""Minimal Markdown -> styled HTML for the strategy PDF (headings, paragraphs, lists, tables,
bold/italic/code/links, rules). Deliberately dependency-free. usage: md2html.py in.md out.html"""
import html
import re
import sys

src, dst = sys.argv[1], sys.argv[2]
lines = open(src, encoding="utf-8").read().splitlines()


def inline(text: str) -> str:
    text = html.escape(text, quote=False)
    text = re.sub(r"`([^`]+)`", r"<code>\1</code>", text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"(?<![*\w])\*([^*]+)\*(?!\w)", r"<em>\1</em>", text)
    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', text)
    return text


out, i = [], 0
while i < len(lines):
    line = lines[i]
    if not line.strip():
        i += 1
        continue
    if line.startswith("#"):
        level = len(line) - len(line.lstrip("#"))
        out.append(f"<h{level}>{inline(line[level:].strip())}</h{level}>")
        i += 1
    elif line.strip() == "---":
        out.append("<hr>")
        i += 1
    elif line.startswith("|"):
        rows = []
        while i < len(lines) and lines[i].startswith("|"):
            rows.append([c.strip() for c in lines[i].strip().strip("|").split("|")])
            i += 1
        head, body = rows[0], [r for r in rows[2:]]
        out.append("<table><thead><tr>" + "".join(f"<th>{inline(c)}</th>" for c in head) + "</tr></thead><tbody>")
        out += ["<tr>" + "".join(f"<td>{inline(c)}</td>" for c in r) + "</tr>" for r in body]
        out.append("</tbody></table>")
    elif re.match(r"^\s*(- |\d+\. )", line):
        ordered = bool(re.match(r"^\d+\. ", line))
        tag = "ol" if ordered else "ul"
        out.append(f"<{tag}>")
        open_li = False
        while i < len(lines) and re.match(r"^\s*(- |\d+\. )", lines[i]):
            item = inline(re.sub(r"^\s*(- |\d+\. )", "", lines[i]))
            if lines[i].startswith("  ") and open_li:
                # Indented sub-bullets belong inside the previous item, so they don't consume list numbers.
                sub = []
                while i < len(lines) and lines[i].startswith("  ") and re.match(r"^\s+- ", lines[i]):
                    text = inline(re.sub(r"^\s+- ", "", lines[i]))
                    sub.append("<li>" + text + "</li>")
                    i += 1
                out[-1] = out[-1][: -len("</li>")] + "<ul>" + "".join(sub) + "</ul></li>"
                continue
            out.append(f"<li>{item}</li>")
            open_li = True
            i += 1
        out.append(f"</{tag}>")
    else:
        para = []
        while i < len(lines) and lines[i].strip() and not re.match(r"^(#|\||---|\s*- |\d+\. )", lines[i]):
            para.append(lines[i].strip())
            i += 1
        out.append(f"<p>{inline(' '.join(para))}</p>")

css = """
@page { size: A4; margin: 14mm 15mm; }
body { font: 9pt/1.36 -apple-system, 'Helvetica Neue', sans-serif; color: #1a1a1a; }
h1 { font-size: 17pt; margin: 0 0 6pt; color: #14284b; }
h2 { font-size: 11.5pt; margin: 9pt 0 3pt; color: #14284b; border-bottom: 1.5px solid #14284b; padding-bottom: 2pt; }
p { margin: 3pt 0 5pt; } ul, ol { margin: 2pt 0 5pt; padding-left: 16pt; } li { margin: 1pt 0; }
li.nested { margin-left: 14pt; list-style: circle; }
table { border-collapse: collapse; width: 100%; margin: 4pt 0 6pt; font-size: 8.2pt; page-break-inside: avoid; }
th, td { border: 1px solid #c9ced8; padding: 2pt 4pt; text-align: left; vertical-align: top; }
th { background: #eef1f6; } code { font: 8.3pt 'SF Mono', Menlo, monospace; background: #f1f2f4; padding: 0 2px; border-radius: 2px; }
a { color: #1f4d99; text-decoration: none; } hr { border: 0; border-top: 1px solid #ddd; margin: 8pt 0; }
"""
open(dst, "w", encoding="utf-8").write(
    f"<!doctype html><html lang=en><meta charset=utf-8><title>Screenshot Testing Strategy</title>"
    f"<style>{css}</style><body>{''.join(out)}</body></html>"
)
print(f"wrote {dst}")
