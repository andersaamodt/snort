#!/usr/bin/env bash

# Orchestrates fetch steps for all enabled modules. Each module may ship a
# `scripts/fetch.sh` that knows how to populate its own cache. This script simply
# locates and executes those module-specific fetchers.

set -euo pipefail

# Resolve the repository root so we can locate the `.env` file regardless of the
# current working directory.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

# Load environment variables if the user has created a `.env` via the wizard.
# shellcheck source=/dev/null
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

# `MODULES` is a comma-separated list (e.g. "nostr,realtime"). Split it into an
# array so we can iterate easily.
MODULES="${MODULES:-}"
IFS=',' read -r -a mods <<< "$MODULES"

# For each enabled module, run its fetch script when it exists and is
# executable. Modules without fetch logic are simply skipped.
for mod in "${mods[@]}"; do
  [[ -n "$mod" ]] || continue
  MOD_FETCH="$ROOT_DIR/../modules/$mod/scripts/fetch.sh"
  if [[ -x "$MOD_FETCH" ]]; then
    "$MOD_FETCH"
  fi
done
