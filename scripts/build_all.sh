#!/usr/bin/env bash
set -euo pipefail

# Build all StitchFlow targets supported on macOS or Linux.
# Usage:
#   ./scripts/build_all.sh dev
#   ./scripts/build_all.sh prod

FLAVOR="${1:-}"
if [[ -z "$FLAVOR" ]]; then
  echo "Usage: ./scripts/build_all.sh <dev|prod>" >&2
  exit 1
fi

FLAVOR="$(echo "$FLAVOR" | tr '[:upper:]' '[:lower:]')"
if [[ "$FLAVOR" != "dev" && "$FLAVOR" != "prod" ]]; then
  echo "[ERROR] Invalid flavor '$FLAVOR'. Use 'dev' or 'prod'." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

flutter pub get
flutter gen-l10n
flutter analyze --fatal-infos

OS="$(uname -s)"
TARGET_FILE="lib/main_${FLAVOR}.dart"
CONFIG_FILE="config/${FLAVOR}.local.json"

# Android APK (any OS with Android SDK)
flutter build apk --release --flavor "$FLAVOR" -t "$TARGET_FILE" --dart-define-from-file="$CONFIG_FILE"
"$SCRIPT_DIR/build_web.sh" "$FLAVOR"

if [[ "$OS" == "Darwin" ]]; then
  "$SCRIPT_DIR/build_macos.sh" "$FLAVOR"
  "$SCRIPT_DIR/build_ios.sh" "$FLAVOR" nocodesign
elif [[ "$OS" == "Linux" ]]; then
  "$SCRIPT_DIR/build_linux.sh" "$FLAVOR"
fi

echo "[OK] Completed supported builds for '$FLAVOR' on $OS under build/releases/$FLAVOR/"
