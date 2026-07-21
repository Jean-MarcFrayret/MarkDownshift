#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
APP_DIR="$PROJECT_DIR/dist/MarkDownshift.app"
CONTENTS_DIR="$APP_DIR/Contents"

cd "$PROJECT_DIR"
swift build -c release --arch arm64 --scratch-path .build/universal-arm64
swift build -c release --arch x86_64 --scratch-path .build/universal-x86_64

mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources"
lipo -create \
  ".build/universal-arm64/arm64-apple-macosx/release/MarkDownshift" \
  ".build/universal-x86_64/x86_64-apple-macosx/release/MarkDownshift" \
  -output "$CONTENTS_DIR/MacOS/MarkDownshift"
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "Resources/AppIcon.icns" "$CONTENTS_DIR/Resources/AppIcon.icns"
chmod +x "$CONTENTS_DIR/MacOS/MarkDownshift"

echo "Built Universal app: $APP_DIR"
