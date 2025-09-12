#!/usr/bin/env bash
# log_warn <message>
# Prints a warning message to stderr.
set -euo pipefail

log_warn() {
  printf '[WARN] %s\n' "$*" >&2
}
