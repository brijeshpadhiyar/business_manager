#!/usr/bin/env bash
set -euo pipefail

# Build StitchFlow Web bundle on macOS/Linux.
# Usage:
#   ./scripts/build_web.sh dev
#   ./scripts/build_web.sh prod

FLAVOR="${1:-}"
MODE="${2:-release}" # release | profile

if [[ -z "$FLAVOR" ]]; then
  echo "Usage: ./scripts/build_web.sh <dev|prod> [release|profile]" >&2
  exit 1
fi

FLAVOR="$(echo "$FLAVOR" | tr '[:upper:]' '[:lower:]')"
MODE="$(echo "$MODE" | tr '[:upper:]' '[:lower:]')"

if [[ "$FLAVOR" != "dev" && "$FLAVOR" != "prod" ]]; then
  echo "[ERROR] Invalid flavor '$FLAVOR'. Use 'dev' or 'prod'." >&2
  exit 1
fi
if [[ "$MODE" != "release" && "$MODE" != "profile" ]]; then
  echo "[ERROR] Invalid Web mode '$MODE'. Use 'release' or 'profile'." >&2
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

flutter build web "--$MODE" -t "$TARGET_FILE" --dart-define-from-file="$CONFIG_FILE"

TIMESTAMP="$(TZ="Asia/Kolkata" date +"%Y%m%d_%H%M%S")"
SUFFIX=""
[[ "$MODE" != "release" ]] && SUFFIX="_${MODE}"
OUT_DIR="$PROJECT_ROOT/build/releases/$FLAVOR/web"
mkdir -p "$OUT_DIR"

NAME="StitchFlow_${FLAVOR_LABEL}_${TIMESTAMP}${SUFFIX}_web"
DEST_DIR="$OUT_DIR/$NAME"
mkdir -p "$DEST_DIR"
cp -a "build/web/." "$DEST_DIR/"
tar -czf "$OUT_DIR/${NAME}.tar.gz" -C "$OUT_DIR" "$NAME"

echo "[OK] Web folder saved to: $DEST_DIR"
echo "[OK] Web archive saved to: $OUT_DIR/${NAME}.tar.gz"
