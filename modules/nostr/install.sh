#!/usr/bin/env bash
# Install script for the nostr module.
#
# Creates a `.env` configuration file by copying from `.env.sample` when
# needed. Running the script multiple times is safe thanks to this check.
set -euo pipefail

# Determine the absolute directory containing this script and load helpers.
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$MODULE_DIR/../lib/scripts/ensure_env.sh"
source "$MODULE_DIR/../lib/scripts/log_info.sh"

# Location of the real and template configuration files.
ENV_FILE="$MODULE_DIR/.env"
SAMPLE_FILE="$MODULE_DIR/.env.sample"

# Copy the template only if no user configuration exists yet.
ensure_env "$ENV_FILE" "$SAMPLE_FILE"

log_info "nostr module installed"
