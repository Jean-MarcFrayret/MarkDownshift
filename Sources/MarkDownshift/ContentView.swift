import SwiftUI
import AppKit

enum ViewMode: String, CaseIterable, Identifiable {
    case edit = "Edit"
    case split = "Split"
    case preview = "Preview"
    var id: Self { self }
}

struct ContentView: View {
    @Binding var text: String
    @State private var mode: ViewMode = .split
    @State private var zoomScale = 1.0

    var body: some View {
        VStack(spacing: 0) {
            FormatToolbar(mode: $mode, zoomScale: $zoomScale)
            Divider()
            Group {
                switch mode {
                case .edit:
                    editor
                case .preview:
                    MarkdownPreview(markdown: text, zoomScale: zoomScale)
                case .split:
                    HSplitView {
                        editor
                        MarkdownPreview(markdown: text, zoomScale: zoomScale)
                    }
                }
            }
        }
    }

    private var editor: some View {
        MarkdownTextEditor(text: $text, fontSize: 15 * zoomScale).frame(minWidth: 300)
    }
}

struct FormatToolbar: View {
    @Binding var mode: ViewMode
    @Binding var zoomScale: Double

    private let minimumZoom = 0.75
    private let maximumZoom = 2.0
    private let zoomStep = 0.125

    var body: some View {
        HStack(spacing: 6) {
            Group {
                formatButton(.heading1, label: "Title")
                formatButton(.heading2, label: "Heading")
                Divider().frame(height: 24)
                formatButton(.bold, systemImage: "bold")
                formatButton(.italic, systemImage: "italic")
                formatButton(.strikethrough, systemImage: "strikethrough")
                Divider().frame(height: 24)
                formatButton(.bulletList, systemImage: "list.bullet")
                formatButton(.numberedList, systemImage: "list.number")
                formatButton(.quote, systemImage: "text.quote")
                formatButton(.link, systemImage: "link")
                formatButton(.code, systemImage: "chevron.left.forwardslash.chevron.right")
            }
            Spacer()
            HStack(spacing: 2) {
                Button { changeZoom(by: -zoomStep) } label: {
                    Image(systemName: "minus.magnifyingglass")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .keyboardShortcut("-", modifiers: .command)
                .disabled(zoomScale <= minimumZoom)
                .help("Zoom Out (⌘−)")

                Button { zoomScale = 1.0 } label: {
                    Text("\(Int((zoomScale * 100).rounded()))%")
                        .monospacedDigit()
                        .frame(width: 42)
                }
                .buttonStyle(.borderless)
                .keyboardShortcut("0", modifiers: .command)
                .help("Actual Size (⌘0)")

                Button { changeZoom(by: zoomStep) } label: {
                    Image(systemName: "plus.magnifyingglass")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .keyboardShortcut("=", modifiers: .command)
                .disabled(zoomScale >= maximumZoom)
                .help("Zoom In (⌘+)")
            }
            Picker("View", selection: $mode) {
                ForEach(ViewMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 190)
            Button {
                NSApp.keyWindow?.performClose(nil)
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.borderless)
            .help("Close File (⌘W)")
        }
        .padding(.horizontal, 10)
        .frame(height: 44)
        .background(.bar)
    }

    private func changeZoom(by amount: Double) {
        zoomScale = min(maximumZoom, max(minimumZoom, zoomScale + amount))
    }

    private func formatButton(_ command: FormatCommand, systemImage: String) -> some View {
        Button { command.send() } label: {
            Image(systemName: systemImage).frame(width: 22, height: 22)
        }
        .buttonStyle(.borderless)
        .help(command.help)
    }

    private func formatButton(_ command: FormatCommand, label: String) -> some View {
        Button(label) { command.send() }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help(command.help)
    }
}

struct MarkdownPreview: View {
    let markdown: String
    let zoomScale: Double

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12 * zoomScale) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                    blockView(block)
                }
            }
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(28 * zoomScale)
        }
        .frame(minWidth: 300)
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var blocks: [MarkdownBlock] { MarkdownBlock.parse(markdown) }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case let .heading(level, text):
            Text(inline(text))
                .font(.system(size: scaled(level == 1 ? 28 : level == 2 ? 23 : 19), weight: .bold))
                .padding(.top, level == 1 ? 6 : 2)
        case let .paragraph(text):
            Text(inline(text)).font(.system(size: scaled(16))).lineSpacing(4 * zoomScale)
        case let .bullet(text):
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text("•").fontWeight(.bold)
                Text(inline(text)).lineSpacing(3)
            }
            .font(.system(size: scaled(16)))
            .padding(.leading, 8)
        case let .numbered(number, text):
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text("\(number).").fontWeight(.semibold).frame(minWidth: 24, alignment: .trailing)
                Text(inline(text)).lineSpacing(3)
            }
            .font(.system(size: scaled(16)))
            .padding(.leading, 4)
        case let .quote(text):
            HStack(spacing: 12) {
                Rectangle().fill(Color.accentColor.opacity(0.7)).frame(width: 3)
                Text(inline(text)).italic().foregroundStyle(.secondary).lineSpacing(3)
            }
            .font(.system(size: scaled(16)))
            .padding(.vertical, 3)
        case let .code(text):
            ScrollView(.horizontal) {
                Text(text)
                    .font(.system(size: scaled(15), design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 7))
        case .rule:
            Divider().padding(.vertical, 5)
        }
    }

    private func inline(_ source: String) -> AttributedString {
        (try? AttributedString(
            markdown: source,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(source)
    }

    private func scaled(_ size: Double) -> Double { size * zoomScale }
}

private enum MarkdownBlock {
    case heading(Int, String)
    case paragraph(String)
    case bullet(String)
    case numbered(Int, String)
    case quote(String)
    case code(String)
    case rule

    static func parse(_ markdown: String) -> [MarkdownBlock] {
        let lines = markdown.components(separatedBy: .newlines)
        var result: [MarkdownBlock] = []
        var paragraph: [String] = []
        var codeLines: [String] = []
        var inCode = false

        func flushParagraph() {
            if !paragraph.isEmpty {
                result.append(.paragraph(paragraph.joined(separator: " ")))
                paragraph.removeAll()
            }
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                flushParagraph()
                if inCode {
                    result.append(.code(codeLines.joined(separator: "\n")))
                    codeLines.removeAll()
                }
                inCode.toggle()
                continue
            }
            if inCode {
                codeLines.append(line)
                continue
            }
            if trimmed.isEmpty {
                flushParagraph()
                continue
            }
            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                flushParagraph()
                result.append(.rule)
                continue
            }
            if let heading = heading(from: trimmed) {
                flushParagraph()
                result.append(.heading(heading.level, heading.text))
                continue
            }
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
                flushParagraph()
                result.append(.bullet(String(trimmed.dropFirst(2))))
                continue
            }
            if let numbered = numberedItem(from: trimmed) {
                flushParagraph()
                result.append(.numbered(numbered.number, numbered.text))
                continue
            }
            if trimmed.hasPrefix("> ") {
                flushParagraph()
                result.append(.quote(String(trimmed.dropFirst(2))))
                continue
            }
            paragraph.append(trimmed)
        }
        flushParagraph()
        if !codeLines.isEmpty { result.append(.code(codeLines.joined(separator: "\n"))) }
        return result
    }

    private static func heading(from line: String) -> (level: Int, text: String)? {
        let count = line.prefix(while: { $0 == "#" }).count
        guard (1...6).contains(count), line.dropFirst(count).first == " " else { return nil }
        return (count, String(line.dropFirst(count + 1)))
    }

    private static func numberedItem(from line: String) -> (number: Int, text: String)? {
        guard let dot = line.firstIndex(of: "."),
              line.index(after: dot) < line.endIndex,
              line[line.index(after: dot)] == " ",
              let number = Int(line[..<dot]) else { return nil }
        return (number, String(line[line.index(dot, offsetBy: 2)...]))
    }
}
