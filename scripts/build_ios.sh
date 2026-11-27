#!/usr/bin/env bash
set -euo pipefail

# Build StitchFlow for iOS on macOS.
# Usage:
#   ./scripts/build_ios.sh dev
#   ./scripts/build_ios.sh prod
#   ./scripts/build_ios.sh dev nocodesign
#   ./scripts/build_ios.sh prod ipa

FLAVOR="${1:-}"
MODE="${2:-ipa}" # ipa | nocodesign | debug

if [[ -z "$FLAVOR" ]]; then
  echo "Usage: ./scripts/build_ios.sh <dev|prod> [ipa|nocodesign|debug]" >&2
  exit 1
fi

FLAVOR="$(echo "$FLAVOR" | tr '[:upper:]' '[:lower:]')"
MODE="$(echo "$MODE" | tr '[:upper:]' '[:lower:]')"

if [[ "$FLAVOR" != "dev" && "$FLAVOR" != "prod" ]]; then
  echo "[ERROR] Invalid flavor '$FLAVOR'. Use 'dev' or 'prod'." >&2
  exit 1
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "[ERROR] iOS builds require macOS with Xcode." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

TARGET_FILE="lib/main_${FLAVOR}.dart"
CONFIG_FILE="config/${FLAVOR}.local.json"
FLAVOR_LABEL="Dev"
[[ "$FLAVOR" == "prod" ]] && FLAVOR_LABEL="Prod"

if [[ ! -f "$TARGET_FILE" ]]; then
  echo "[ERROR] Missing entrypoint: $TARGET_FILE" >&2
  exit 1
fi
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "[ERROR] Missing config: $CONFIG_FILE" >&2
  exit 1
fi

TIMESTAMP="$(TZ="Asia/Kolkata" date +"%Y%m%d_%H%M%S")"
OUT_DIR="$PROJECT_ROOT/build/releases/$FLAVOR/ios"
mkdir -p "$OUT_DIR"

case "$MODE" in
  ipa)
    flutter build ipa --release -t "$TARGET_FILE" --dart-define-from-file="$CONFIG_FILE"
    IPA_FILE="$(find build/ios/ipa -maxdepth 1 -name '*.ipa' | head -n 1 || true)"
    if [[ -z "$IPA_FILE" ]]; then
      echo "[ERROR] No .ipa generated under build/ios/ipa." >&2
      exit 1
    fi
    DEST="$OUT_DIR/StitchFlow_${FLAVOR_LABEL}_${TIMESTAMP}.ipa"
    cp -f "$IPA_FILE" "$DEST"
    echo "[OK] iOS IPA saved to: $DEST"
    ;;
  nocodesign)
    flutter build ios --release --no-codesign -t "$TARGET_FILE" --dart-define-from-file="$CONFIG_FILE"
    APP_DIR="build/ios/iphoneos/Runner.app"
    if [[ ! -d "$APP_DIR" ]]; then
      echo "[ERROR] Runner.app not found at $APP_DIR" >&2
      exit 1
    fi
    DEST="$OUT_DIR/StitchFlow_${FLAVOR_LABEL}_${TIMESTAMP}_unsigned.app"
    rm -rf "$DEST"
    ditto "$APP_DIR" "$DEST"
    echo "[OK] Unsigned iOS .app saved to: $DEST"
    ;;
  debug)
    flutter build ios --debug --no-codesign -t "$TARGET_FILE" --dart-define-from-file="$CONFIG_FILE"
    APP_DIR="build/ios/iphoneos/Runner.app"
    DEST="$OUT_DIR/StitchFlow_${FLAVOR_LABEL}_${TIMESTAMP}_debug.app"
    rm -rf "$DEST"
    ditto "$APP_DIR" "$DEST"
    echo "[OK] Debug iOS .app saved to: $DEST"
    ;;
  *)
    echo "[ERROR] Unknown mode '$MODE'. Use 'ipa', 'nocodesign', or 'debug'." >&2
    exit 1
    ;;
esac
