#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
APP_DIR="$PROJECT_DIR/dist/MarkDownshift.app"
CONTENTS_DIR="$APP_DIR/Contents"
BUILD_HOME="$PROJECT_DIR/.build-home"

cd "$PROJECT_DIR"
mkdir -p "$BUILD_HOME/cache" "$BUILD_HOME/config" "$BUILD_HOME/security" "$BUILD_HOME/clang"
HOME="$BUILD_HOME" \
XDG_CACHE_HOME="$BUILD_HOME/cache" \
XDG_CONFIG_HOME="$BUILD_HOME/config" \
SWIFTPM_SECURITY_DIRECTORY="$BUILD_HOME/security" \
CLANG_MODULE_CACHE_PATH="$BUILD_HOME/clang" \
swift build -c release

mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources"
cp ".build/release/MarkDownshift" "$CONTENTS_DIR/MacOS/MarkDownshift"
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "Resources/AppIcon.icns" "$CONTENTS_DIR/Resources/AppIcon.icns"
chmod +x "$CONTENTS_DIR/MacOS/MarkDownshift"

echo "Built: $APP_DIR"
