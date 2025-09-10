#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0" >&2
  exit 1
}

main() {
  [ "$#" -eq 0 ] || usage
  : "${RUNTIME_ROOT?need RUNTIME_ROOT}"
  local dir="$RUNTIME_ROOT/unix-auth"
  mkdir -p "$dir"
  local file
  file="${dir}/challenge-$(date +%s%N)"
  head -c 32 /dev/urandom | base64 -w0 > "$file"
  echo "$file"
}

main "$@"
