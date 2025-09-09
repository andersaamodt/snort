#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
EXAMPLE_FILE="$ROOT_DIR/.env.example"

if [[ -f "$ENV_FILE" ]]; then
  echo "\"$ENV_FILE\" already exists" >&2
  exit 1
fi

cp "$EXAMPLE_FILE" "$ENV_FILE"
