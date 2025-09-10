#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE_DIR="$MODULE_DIR/../../core"
ENV_FILE="$CORE_DIR/.env"

# shellcheck source=../../core/.env
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

UPLOADS_ROOT="${UPLOADS_ROOT:-$CORE_DIR/../uploads}"
UPLOAD_ROLES="${UPLOAD_ROLES:-admins,authors}"
UPLOAD_MAX_MB="${UPLOAD_MAX_MB:-2048}"

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <file>" >&2
  exit 1
fi

src="$1"
[[ -f "$src" ]] || {
  echo "no such file: $src" >&2
  exit 1
}

role="${UPLOAD_ROLE:-}"
if [[ -z "$role" || ",${UPLOAD_ROLES}," != *",${role},"* ]]; then
  echo "role not permitted" >&2
  exit 1
fi

size_bytes=$(stat -c%s "$src")
max_bytes=$((UPLOAD_MAX_MB * 1024 * 1024))
if ((size_bytes > max_bytes)); then
  echo "file too large" >&2
  exit 1
fi

mkdir -p "$UPLOADS_ROOT"
dest="$UPLOADS_ROOT/$(basename "$src")"
cp "$src" "$dest"

if [[ -n "${LOG_ROOT:-}" ]]; then
  mkdir -p "$LOG_ROOT"
  mime=$(file -b --mime-type "$dest" 2> /dev/null || echo unknown)
  echo "$(date -Is) role=$role path=$dest size=$size_bytes mime=$mime" >> "$LOG_ROOT/uploads.log"
fi
