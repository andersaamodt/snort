#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE_DIR="$MODULE_DIR/../../core"
ENV_FILE="$CORE_DIR/.env"

# shellcheck source=../../core/.env
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

UPLOADS_ROOT="${UPLOADS_ROOT:-$CORE_DIR/../uploads}"
UPLOAD_ROLES="${UPLOAD_ROLES:-admins,authors}"

role="${UPLOAD_ROLE:-}"
if [[ -z "$role" || ",${UPLOAD_ROLES}," != *",${role},"* ]]; then
  echo "role not permitted" >&2
  exit 1
fi

[[ -d "$UPLOADS_ROOT" ]] || {
  echo '[]'
  exit 0
}

first=1
echo '['
find "$UPLOADS_ROOT" -maxdepth 1 -type f | sort | while read -r file; do
  if ((first)); then
    first=0
  else
    echo ','
  fi
  printf '  "%s"' "$(basename "$file")"
done
echo
echo ']'
