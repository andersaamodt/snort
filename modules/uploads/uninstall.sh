#!/usr/bin/env bash
# Uninstall script for the uploads module.
#
# Removes the generated `.env` file if present.
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$MODULE_DIR/../lib/scripts/remove_env.sh"
source "$MODULE_DIR/../lib/scripts/log_info.sh"

ENV_FILE="$MODULE_DIR/.env"

remove_env "$ENV_FILE"

log_info "uploads module uninstalled"
