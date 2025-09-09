#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 <username>" >&2
  exit 1
}

main() {
  [ "${1:-}" ] || usage
  local name="$1"
  if [[ ! "$name" =~ ^[a-z]{1,32}$ ]]; then
    echo "invalid username" >&2
    exit 1
  fi
  if id -u "$name" > /dev/null 2>&1; then
    echo "user exists" >&2
    exit 1
  fi
  echo "ok"
}

main "$@"
