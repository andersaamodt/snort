#!/usr/bin/env bash
set -euo pipefail

id="${1:-}" # event id hex
bits="${2:-22}"

if [[ -z "$id" || -z "$bits" ]]; then
  echo "usage: $0 <event-id-hex> [bits]" >&2
  exit 1
fi

if [[ ! "$id" =~ ^[0-9a-fA-F]{64}$ ]]; then
  echo "invalid id" >&2
  exit 1
fi

# number of full hex zeros and remaining bits
nfull=$((bits / 4))
partial=$((bits % 4))

# check full zero nibbles
prefix="${id:0:nfull}"
if [[ "$prefix" != $(printf '0%.0s' $(seq 1 $nfull)) ]]; then
  echo "insufficient pow" >&2
  exit 1
fi

if ((partial > 0)); then
  hex_digit="${id:nfull:1}"
  value=$((16#${hex_digit}))
  max=$((1 << (4 - partial)))
  if ((value >= max)); then
    echo "insufficient pow" >&2
    exit 1
  fi
fi
