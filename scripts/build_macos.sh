#!/usr/bin/env bash
set -euo pipefail

# Build StitchFlow macOS desktop app (.app).
# Usage:
#   ./scripts/build_macos.sh dev
#   ./scripts/build_macos.sh prod
#   ./scripts/build_macos.sh dev debug

FLAVOR="${1:-}"
MODE="${2:-release}" # release | debug | profile

if [[ -z "$FLAVOR" ]]; then
  echo "Usage: ./scripts/build_macos.sh <dev|prod> [release|debug|profile]" >&2
  exit 1
fi

FLAVOR="$(echo "$FLAVOR" | tr '[:upper:]' '[:lower:]')"
MODE="$(echo "$MODE" | tr '[:upper:]' '[:lower:]')"

if [[ "$FLAVOR" != "dev" && "$FLAVOR" != "prod" ]]; then
  echo "[ERROR] Invalid flavor '$FLAVOR'. Use 'dev' or 'prod'." >&2
  exit 1
fi
if [[ "$MODE" != "release" && "$MODE" != "debug" && "$MODE" != "profile" ]]; then
  echo "[ERROR] Invalid mode '$MODE'. Use 'release', 'debug', or 'profile'." >&2
  exit 1
fi
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "[ERROR] macOS builds require a macOS host with Xcode." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

TARGET_FILE="lib/main_${FLAVOR}.dart"
CONFIG_FILE="config/${FLAVOR}.local.json"
FLAVOR_LABEL="Dev"
[[ "$FLAVOR" == "prod" ]] && FLAVOR_LABEL="Prod"

if [[ ! -f "$TARGET_FILE" || ! -f "$CONFIG_FILE" ]]; then
  echo "[ERROR] Missing entrypoint ($TARGET_FILE) or config ($CONFIG_FILE)." >&2
  exit 1
fi

flutter build macos "--$MODE" -t "$TARGET_FILE" --dart-define-from-file="$CONFIG_FILE"

MODE_DIR="$(tr '[:lower:]' '[:upper:]' <<< "${MODE:0:1}")${MODE:1}"
SRC_APP="build/macos/Build/Products/${MODE_DIR}/StitchFlow.app"
if [[ ! -d "$SRC_APP" ]]; then
  echo "[ERROR] Expected macOS bundle not found: $SRC_APP" >&2
  exit 1
fi

TIMESTAMP="$(TZ="Asia/Kolkata" date +"%Y%m%d_%H%M%S")"
SUFFIX=""
[[ "$MODE" != "release" ]] && SUFFIX="_${MODE}"
OUT_DIR="$PROJECT_ROOT/build/releases/$FLAVOR/macos"
mkdir -p "$OUT_DIR"

DEST_APP="$OUT_DIR/StitchFlow_${FLAVOR_LABEL}_${TIMESTAMP}${SUFFIX}.app"
rm -rf "$DEST_APP"
ditto "$SRC_APP" "$DEST_APP"
(cd "$OUT_DIR" && ditto -c -k --sequesterRsrc --keepParent "$(basename "$DEST_APP")" "$(basename "$DEST_APP" .app).zip")

echo "[OK] macOS .app saved to: $DEST_APP"
echo "[OK] macOS .zip saved to: ${DEST_APP%.app}.zip"
