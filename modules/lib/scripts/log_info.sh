#!/usr/bin/env bash
# log_info <message>
# Prints an informational message.
set -euo pipefail

log_info() {
  printf '[INFO] %s\n' "$*"
}
