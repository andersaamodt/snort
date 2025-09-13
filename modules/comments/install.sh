#!/usr/bin/env bash
# Install script for the comments module.
#
# Generates `.env` from `.env.sample` when missing. Safe to run multiple times.
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$MODULE_DIR/../lib/scripts/ensure_env.sh"
source "$MODULE_DIR/../lib/scripts/log_info.sh"

ENV_FILE="$MODULE_DIR/.env"
SAMPLE_FILE="$MODULE_DIR/.env.sample"

ensure_env "$ENV_FILE" "$SAMPLE_FILE"

log_info "comments module installed"
