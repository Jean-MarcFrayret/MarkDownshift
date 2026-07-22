import Foundation
import PDFKit

let destination = FileManager.default.temporaryDirectory
    .appendingPathComponent("MarkDownshift-PDF-test-\(UUID().uuidString).pdf")
defer { try? FileManager.default.removeItem(at: destination) }

try PDFExporter.write(
    markdown: "# Export Test\n\nThis text must appear in the PDF.\n\n- First item\n- Second item",
    to: destination
)

guard let pdf = PDFDocument(url: destination), pdf.pageCount > 0 else {
    fatalError("Exporter did not create a readable PDF")
}
let text = (0..<pdf.pageCount)
    .compactMap { pdf.page(at: $0)?.string }
    .joined(separator: "\n")
for expected in ["Export Test", "This text must appear in the PDF.", "First item"] {
    guard text.contains(expected) else {
        fatalError("Exported PDF is missing expected text: \(expected)")
    }
}
print("PDF export verified: \(pdf.pageCount) page(s), expected text present")
