#!/usr/bin/env bash
# remove_env <env_file>
# Removes <env_file> if it exists.
set -euo pipefail

remove_env() {
  local env_file="$1"
  if [[ -f "$env_file" ]]; then
    rm "$env_file"
  fi
}
