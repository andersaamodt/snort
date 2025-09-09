#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

# shellcheck source=/dev/null
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

MODULES="${MODULES:-}"
IFS=',' read -r -a mods <<< "$MODULES"
for mod in "${mods[@]}"; do
  [[ -n "$mod" ]] || continue
  MOD_FETCH="$ROOT_DIR/../modules/$mod/scripts/fetch.sh"
  if [[ -x "$MOD_FETCH" ]]; then
    "$MOD_FETCH"
  fi
done
