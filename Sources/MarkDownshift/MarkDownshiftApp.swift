import SwiftUI
import UniformTypeIdentifiers

@main
struct MarkDownshiftApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownFile()) { file in
            ContentView(
                text: file.$document.text,
                documentName: file.fileURL?.deletingPathExtension().lastPathComponent
            )
                .frame(minWidth: 760, minHeight: 500)
        }
        .commands {
            CommandMenu("Format") {
                Button("Bold") { FormatCommand.bold.send() }.keyboardShortcut("b")
                Button("Italic") { FormatCommand.italic.send() }.keyboardShortcut("i")
                Divider()
                Button("Title") { FormatCommand.heading1.send() }
                Button("Heading") { FormatCommand.heading2.send() }
                Button("Bulleted List") { FormatCommand.bulletList.send() }
                Button("Numbered List") { FormatCommand.numberedList.send() }
                Button("Quote") { FormatCommand.quote.send() }
                Button("Link") { FormatCommand.link.send() }.keyboardShortcut("k")
                Button("Inline Code") { FormatCommand.code.send() }
            }
        }
    }
}

struct MarkdownFile: FileDocument {
    static var readableContentTypes: [UTType] { [.markdown, .plainText] }
    static var writableContentTypes: [UTType] { [.markdown] }

    var text = ""

    init() {}

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        guard let decoded = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        text = decoded
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = text.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}

extension UTType {
    static var markdown: UTType { UTType(filenameExtension: "md") ?? .plainText }
}
