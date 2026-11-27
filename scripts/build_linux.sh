#!/usr/bin/env bash
set -euo pipefail

# Build StitchFlow Linux desktop bundle.
# Usage:
#   ./scripts/build_linux.sh dev
#   ./scripts/build_linux.sh prod
#   ./scripts/build_linux.sh dev debug

FLAVOR="${1:-}"
MODE="${2:-release}" # release | debug | profile

if [[ -z "$FLAVOR" ]]; then
  echo "Usage: ./scripts/build_linux.sh <dev|prod> [release|debug|profile]" >&2
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
if [[ "$(uname -s)" != "Linux" ]]; then
  echo "[ERROR] Linux builds require a Linux host (clang, cmake, ninja-build, libgtk-3-dev)." >&2
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

flutter build linux "--$MODE" -t "$TARGET_FILE" --dart-define-from-file="$CONFIG_FILE"

BUNDLE_DIR="build/linux/x64/${MODE}/bundle"
if [[ ! -d "$BUNDLE_DIR" ]]; then
  echo "[ERROR] Expected Linux bundle not found: $BUNDLE_DIR" >&2
  exit 1
fi

TIMESTAMP="$(TZ="Asia/Kolkata" date +"%Y%m%d_%H%M%S")"
SUFFIX=""
[[ "$MODE" != "release" ]] && SUFFIX="_${MODE}"
OUT_DIR="$PROJECT_ROOT/build/releases/$FLAVOR/linux"
mkdir -p "$OUT_DIR"

NAME="StitchFlow_${FLAVOR_LABEL}_${TIMESTAMP}${SUFFIX}_linux"
DEST_DIR="$OUT_DIR/$NAME"
mkdir -p "$DEST_DIR"
cp -a "$BUNDLE_DIR/." "$DEST_DIR/"
tar -czf "$OUT_DIR/${NAME}.tar.gz" -C "$OUT_DIR" "$NAME"

echo "[OK] Linux bundle saved to: $DEST_DIR"
echo "[OK] Linux archive saved to: $OUT_DIR/${NAME}.tar.gz"
