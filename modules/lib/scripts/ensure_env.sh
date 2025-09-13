#!/usr/bin/env bash
# ensure_env <env_file> <sample_file>
# Copies <sample_file> to <env_file> if the env file does not exist.
set -euo pipefail

ensure_env() {
  local env_file="$1"
  local sample_file="$2"
  if [[ ! -f "$env_file" ]]; then
    cp "$sample_file" "$env_file"
  fi
}
