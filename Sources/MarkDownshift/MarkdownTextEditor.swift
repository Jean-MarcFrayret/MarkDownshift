import SwiftUI
import AppKit

extension Notification.Name {
    static let markdownFormat = Notification.Name("MarkDownshift.markdownFormat")
}

enum FormatCommand: String, CaseIterable {
    case heading1, heading2, bold, italic, strikethrough, bulletList, numberedList, quote, link, code

    var help: String {
        switch self {
        case .heading1: "Title"
        case .heading2: "Heading"
        case .bold: "Bold (⌘B)"
        case .italic: "Italic (⌘I)"
        case .strikethrough: "Strikethrough"
        case .bulletList: "Bulleted list"
        case .numberedList: "Numbered list"
        case .quote: "Quote"
        case .link: "Link"
        case .code: "Inline code"
        }
    }

    func send() {
        NotificationCenter.default.post(name: .markdownFormat, object: self)
    }

}

struct MarkdownTextEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder

        let editor = NSTextView()
        editor.isRichText = false
        editor.isAutomaticQuoteSubstitutionEnabled = false
        editor.isAutomaticDashSubstitutionEnabled = false
        editor.allowsUndo = true
        editor.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        editor.textContainerInset = NSSize(width: 18, height: 18)
        editor.string = text
        editor.delegate = context.coordinator
        editor.autoresizingMask = [.width]
        editor.isVerticallyResizable = true
        editor.isHorizontallyResizable = false
        editor.textContainer?.widthTracksTextView = true
        scroll.documentView = editor
        context.coordinator.editor = editor
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let editor = scroll.documentView as? NSTextView, editor.string != text else { return }
        let selection = editor.selectedRange()
        editor.string = text
        editor.setSelectedRange(NSRange(location: min(selection.location, text.utf16.count), length: 0))
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownTextEditor
        weak var editor: NSTextView?
        private var observer: NSObjectProtocol?

        init(_ parent: MarkdownTextEditor) {
            self.parent = parent
            super.init()
            observer = NotificationCenter.default.addObserver(
                forName: .markdownFormat, object: nil, queue: .main
            ) { [weak self] note in
                guard let command = note.object as? FormatCommand else { return }
                self?.apply(command)
            }
        }

        deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }

        func textDidChange(_ notification: Notification) {
            guard let editor else { return }
            parent.text = editor.string
        }

        private func apply(_ command: FormatCommand) {
            guard let editor, editor.window?.firstResponder === editor else {
                editor?.window?.makeFirstResponder(editor)
                return apply(command)
            }
            switch command {
            case .bold: wrap("**", "**", placeholder: "bold text")
            case .italic: wrap("*", "*", placeholder: "italic text")
            case .strikethrough: wrap("~~", "~~", placeholder: "strikethrough")
            case .link: wrap("[", "](https://)", placeholder: "link text")
            case .code: wrap("`", "`", placeholder: "code")
            case .heading1: prefixLines("# ")
            case .heading2: prefixLines("## ")
            case .bulletList: prefixLines("- ")
            case .numberedList: prefixNumberedLines()
            case .quote: prefixLines("> ")
            }
        }

        private func wrap(_ before: String, _ after: String, placeholder: String) {
            guard let editor else { return }
            let range = editor.selectedRange()
            let selected = range.length > 0 ? (editor.string as NSString).substring(with: range) : placeholder
            let replacement = before + selected + after
            editor.insertText(replacement, replacementRange: range)
            editor.setSelectedRange(NSRange(location: range.location + before.utf16.count, length: selected.utf16.count))
        }

        private func prefixLines(_ prefix: String) {
            guard let editor else { return }
            let string = editor.string as NSString
            let selected = editor.selectedRange()
            let lineRange = string.lineRange(for: selected)
            let content = string.substring(with: lineRange)
            let replacement = content.split(separator: "\n", omittingEmptySubsequences: false)
                .map { prefix + $0 }.joined(separator: "\n")
            editor.insertText(replacement, replacementRange: lineRange)
        }

        private func prefixNumberedLines() {
            guard let editor else { return }
            let string = editor.string as NSString
            let lineRange = string.lineRange(for: editor.selectedRange())
            let lines = string.substring(with: lineRange).split(separator: "\n", omittingEmptySubsequences: false)
            let replacement = lines.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
            editor.insertText(replacement, replacementRange: lineRange)
        }
    }
}
