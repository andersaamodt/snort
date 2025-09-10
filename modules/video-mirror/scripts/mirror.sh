#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE_DIR="$MODULE_DIR/../../core"
ENV_FILE="$CORE_DIR/.env"

# shellcheck source=../../core/.env
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

MIRRORS_ROOT="${MIRRORS_ROOT:-$CORE_DIR/../mirrors}"
FFMPEG_PRESET="${FFMPEG_PRESET:-veryfast}"
FFMPEG_CRF="${FFMPEG_CRF:-20}"

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <video-file>" >&2
  exit 1
fi

in="$1"
[[ -f "$in" ]] || {
  echo "no such file: $in" >&2
  exit 1
}

raw_dir="$MIRRORS_ROOT/raw"
mp4_dir="$MIRRORS_ROOT/mp4"
mkdir -p "$raw_dir" "$mp4_dir"

base="$(basename "$in")"
cp "$in" "$raw_dir/$base"

out="$mp4_dir/${base%.*}.mp4"
ffmpeg -loglevel error -i "$in" \
  -vf scale=-2:720 -c:v libx264 -preset "$FFMPEG_PRESET" -crf "$FFMPEG_CRF" \
  -c:a aac -b:a 160k "$out"
