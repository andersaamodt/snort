#!/usr/bin/env bash

# Bootstrap helper that copies `.env.example` to `.env`.  It refuses to overwrite
# an existing `.env` to avoid clobbering user configuration.

set -euo pipefail

# Locate the repository root and relevant files.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
EXAMPLE_FILE="$ROOT_DIR/.env.example"

# Guard against accidental overwrite by exiting if `.env` already exists.
if [[ -f "$ENV_FILE" ]]; then
  echo "\"$ENV_FILE\" already exists" >&2
  exit 1
fi

# Copy the template file to produce a working `.env` for the user to edit.
cp "$EXAMPLE_FILE" "$ENV_FILE"
