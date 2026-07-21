#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
"$PROJECT_DIR/scripts/build-app.sh"

SOURCE_APP="$PROJECT_DIR/dist/MarkDownshift.app"
DEST_APP="/Applications/MarkDownshift.app"

ditto "$SOURCE_APP" "$DEST_APP"
echo "Installed: $DEST_APP"
echo "Open Applications, then drag MarkDownshift to your Dock."
