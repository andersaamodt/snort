#!/usr/bin/env bash
# log_err <message>
# Prints an error message to stderr.
set -euo pipefail

log_err() {
  printf '[ERROR] %s\n' "$*" >&2
}
