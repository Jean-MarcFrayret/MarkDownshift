import SwiftUI

private struct ExportPDFActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var exportPDF: (() -> Void)? {
        get { self[ExportPDFActionKey.self] }
        set { self[ExportPDFActionKey.self] = newValue }
    }
}

struct ExportCommands: Commands {
    @FocusedValue(\.exportPDF) private var exportPDF

    var body: some Commands {
        CommandGroup(after: .saveItem) {
            Divider()
            Menu("Export") {
                Button("Export as PDF…") { exportPDF?() }
                    .disabled(exportPDF == nil)
            }
        }
    }
}
