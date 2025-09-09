#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE_DIR="$MODULE_DIR/../../core"
ENV_FILE="$CORE_DIR/.env"

# shellcheck source=../../core/.env
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

UPLOADS_ROOT="${UPLOADS_ROOT:-$CORE_DIR/../uploads}"

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <file>" >&2
  exit 1
fi

src="$1"
[[ -f "$src" ]] || {
  echo "no such file: $src" >&2
  exit 1
}

mkdir -p "$UPLOADS_ROOT"
cp "$src" "$UPLOADS_ROOT/"
