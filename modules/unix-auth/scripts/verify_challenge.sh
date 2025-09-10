#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 <pubkey_file> <challenge_file> <signature_file>" >&2
  exit 1
}

main() {
  [ "$#" -eq 3 ] || usage
  local pubkey="$1" challenge="$2" sig="$3"

  for f in "$pubkey" "$challenge" "$sig"; do
    if [[ ! -f "$f" ]]; then
      echo "file not found: $f" >&2
      exit 1
    fi
  done

  local allowed principal keytype keydata
  principal=$(awk '{print $3}' "$pubkey")
  keytype=$(awk '{print $1}' "$pubkey")
  keydata=$(awk '{print $2}' "$pubkey")

  allowed=$(mktemp)
  trap 'rm -f "${allowed:-}"' EXIT
  printf '%s %s %s\n' "$principal" "$keytype" "$keydata" > "$allowed"

  if ssh-keygen -Y verify -f "$allowed" -I "$principal" -n snort -s "$sig" < "$challenge" > /dev/null 2>&1; then
    echo "ok"
  else
    echo "invalid signature" >&2
    exit 1
  fi
}

main "$@"
