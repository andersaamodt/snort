#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

# shellcheck source=/dev/null
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

SITE_ROOT="${SITE_ROOT:-$ROOT_DIR/../site}"
DEST="$SITE_ROOT/current/public"

mkdir -p "$DEST"
rsync -a "$ROOT_DIR/public/" "$DEST/"
