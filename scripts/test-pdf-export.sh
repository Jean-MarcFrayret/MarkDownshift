#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
CHECK_DIR="$PROJECT_DIR/.build/pdf-export-check"
mkdir -p "$CHECK_DIR"

xcrun swiftc \
  "$PROJECT_DIR/Sources/MarkDownshift/ContentView.swift" \
  "$PROJECT_DIR/Sources/MarkDownshift/ExportCommands.swift" \
  "$PROJECT_DIR/Sources/MarkDownshift/MarkdownTextEditor.swift" \
  "$PROJECT_DIR/Sources/MarkDownshift/PDFExporter.swift" \
  "$PROJECT_DIR/Tests/PDFExportCheck/main.swift" \
  -o "$CHECK_DIR/PDFExportCheck"

"$CHECK_DIR/PDFExportCheck"
