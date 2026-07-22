import AppKit
import CoreText
import CoreGraphics
import UniformTypeIdentifiers

enum PDFExporter {
    @MainActor
    static func export(markdown: String, suggestedName: String?) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "\(suggestedName ?? "Untitled").pdf"

        guard panel.runModal() == .OK, let destination = panel.url else { return }
        do {
            try write(markdown: markdown, to: destination)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    static func write(markdown: String, to destination: URL) throws {
        let html = MarkdownHTMLRenderer.render(markdown)
        guard let htmlData = html.data(using: .utf8) else { throw PDFExportError.encoding }
        let attributed = try NSAttributedString(
            data: htmlData,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )

        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let consumer = CGDataConsumer(url: destination as CFURL),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw PDFExportError.cannotCreateFile
        }

        let framesetter = CTFramesetterCreateWithAttributedString(attributed)
        let contentRect = CGRect(x: 44, y: 44, width: 524, height: 704)
        var offset = 0
        repeat {
            context.beginPDFPage(nil)
            let path = CGPath(rect: contentRect, transform: nil)
            let frame = CTFramesetterCreateFrame(
                framesetter,
                CFRange(location: offset, length: 0),
                path,
                nil
            )
            CTFrameDraw(frame, context)
            let visible = CTFrameGetVisibleStringRange(frame)
            context.endPDFPage()
            guard visible.length > 0 || attributed.length == 0 else {
                context.closePDF()
                throw PDFExportError.layout
            }
            offset += visible.length
        } while offset < attributed.length
        context.closePDF()
    }
}

private enum PDFExportError: LocalizedError {
    case encoding, cannotCreateFile, layout

    var errorDescription: String? {
        switch self {
        case .encoding: "The Markdown document could not be encoded for PDF export."
        case .cannotCreateFile: "The PDF file could not be created at the selected location."
        case .layout: "The document could not be laid out on a PDF page."
        }
    }
}

private enum MarkdownHTMLRenderer {
    static func render(_ markdown: String) -> String {
        let content = MarkdownBlock.parse(markdown).map(html).joined(separator: "\n")
        return """
        <!doctype html>
        <html><head><meta charset="utf-8"><style>
        @page { margin: 0; }
        body { color: #181818; background: white; font: 12pt -apple-system, BlinkMacSystemFont, sans-serif; line-height: 1.5; margin: 0; }
        h1 { font-size: 25pt; margin: 0 0 14pt; line-height: 1.18; }
        h2 { font-size: 20pt; margin: 18pt 0 10pt; line-height: 1.2; }
        h3, h4, h5, h6 { font-size: 16pt; margin: 15pt 0 8pt; }
        p { margin: 0 0 10pt; }
        .item { margin: 0 0 5pt 18pt; text-indent: -14pt; }
        blockquote { border-left: 3pt solid #b48a18; color: #555; margin: 10pt 0; padding: 2pt 0 2pt 12pt; }
        pre { background: #f2f2f2; border-radius: 5pt; font: 10.5pt ui-monospace, Menlo, monospace; padding: 10pt; white-space: pre-wrap; break-inside: avoid; }
        code { background: #f2f2f2; font: 0.92em ui-monospace, Menlo, monospace; padding: 1pt 3pt; }
        hr { border: 0; border-top: 1pt solid #bbb; margin: 16pt 0; }
        a { color: #8b1a1a; text-decoration: underline; }
        </style></head><body>\(content)</body></html>
        """
    }

    private static func html(_ block: MarkdownBlock) -> String {
        switch block {
        case let .heading(level, text):
            return "<h\(level)>\(inline(text))</h\(level)>"
        case let .paragraph(text):
            return "<p>\(inline(text))</p>"
        case let .bullet(text):
            return "<div class=\"item\">&#8226;&nbsp; \(inline(text))</div>"
        case let .numbered(number, text):
            return "<div class=\"item\">\(number).&nbsp; \(inline(text))</div>"
        case let .quote(text):
            return "<blockquote>\(inline(text))</blockquote>"
        case let .code(text):
            return "<pre>\(escape(text))</pre>"
        case .rule:
            return "<hr>"
        }
    }

    private static func inline(_ source: String) -> String {
        var result = escape(source)
        result = replace(#"\[([^\]]+)\]\(([^\)]+)\)"#, in: result, with: #"<a href="$2">$1</a>"#)
        result = replace(#"`([^`]+)`"#, in: result, with: "<code>$1</code>")
        result = replace(#"\*\*([^*]+)\*\*"#, in: result, with: "<strong>$1</strong>")
        result = replace(#"~~([^~]+)~~"#, in: result, with: "<del>$1</del>")
        result = replace(#"(?<!\*)\*([^*]+)\*(?!\*)"#, in: result, with: "<em>$1</em>")
        return result
    }

    private static func replace(_ pattern: String, in source: String, with template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return source }
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        return regex.stringByReplacingMatches(in: source, range: range, withTemplate: template)
    }

    private static func escape(_ source: String) -> String {
        source
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
