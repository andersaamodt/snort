#!/usr/bin/env bash
# require_env <name>
# Exits with an error if the environment variable <name> is unset or empty.
set -euo pipefail

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "error: required env var '$name' is not set" >&2
    return 1
  fi
}
