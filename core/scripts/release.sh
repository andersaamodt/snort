#!/usr/bin/env bash

# Sync the generated HTML from `core/public/` into the site tree pointed to by
# `SITE_ROOT`. This is typically invoked after a successful render to publish
# the new site atomically.

set -euo pipefail

# Resolve repository root and load environment variables if available.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

# shellcheck source=/dev/null
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

# If `SITE_ROOT` isn't set in the environment, default to a sibling directory
# next to the repository. The release target is `$SITE_ROOT/current/public`.
SITE_ROOT="${SITE_ROOT:-$ROOT_DIR/../site}"
DEST="$SITE_ROOT/current/public"

# Ensure the destination exists and then copy the newly rendered files. `rsync`
# preserves timestamps and only transfers changed files.
mkdir -p "$DEST"
rsync -a "$ROOT_DIR/public/" "$DEST/"
