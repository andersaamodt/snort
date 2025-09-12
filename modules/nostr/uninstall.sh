#!/usr/bin/env bash
# Uninstall script for the nostr module.
#
# Removes the generated `.env` file if it exists so the module can be cleanly
# disabled. Running multiple times is safe.
set -euo pipefail

# Determine the absolute directory containing this script and load helpers.
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$MODULE_DIR/../lib/scripts/remove_env.sh"
source "$MODULE_DIR/../lib/scripts/log_info.sh"

# Location of the configuration file to remove.
ENV_FILE="$MODULE_DIR/.env"

# Delete the file when present.
remove_env "$ENV_FILE"

log_info "nostr module uninstalled"
