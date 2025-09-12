#!/usr/bin/env bash
# Interactive helper to enable or disable Snort modules.
# Copies module `.env.sample` files via each module's install script and
# removes them via uninstall scripts.  Updates the root `.env` MODULES list.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

# Discover available modules by scanning subdirectories that contain install.sh.
mapfile -t AVAILABLE < <(for d in "$ROOT_DIR"/modules/*; do
  [ -d "$d" ] || continue
  base="$(basename "$d")"
  [[ "$base" == "lib" || "$base" == "manage" ]] && continue
  [ -f "$d/install.sh" ] && echo "$base"
done)

# Read currently enabled modules from .env.
CURRENT=""
if [[ -f "$ENV_FILE" ]] && grep -q '^MODULES=' "$ENV_FILE"; then
  CURRENT="$(grep '^MODULES=' "$ENV_FILE" | cut -d= -f2)"
fi
IFS=',' read -r -a ENABLED <<< "$CURRENT"

prompt_modules() {
  # If MODULES_AUTO is set (comma or space separated), use it non-interactively.
  if [[ ${MODULES_AUTO+x} ]]; then
    IFS=',' read -r -a sel <<< "${MODULES_AUTO// /,}"
    printf '%s\n' "${sel[@]}"
    return
  fi

  selections=()
  for mod in "${AVAILABLE[@]}"; do
    def="n"
    [[ " ${ENABLED[*]} " == *" $mod "* ]] && def="y"
    read -rp "Enable $mod? [y/N] " ans
    ans=${ans:-$def}
    if [[ "$ans" =~ ^[Yy]$ ]]; then
      selections+=("$mod")
    fi
  done
  printf '%s\n' "${selections[@]}"
}

mapfile -t SELECTED < <(prompt_modules)

# Update MODULES in .env.
NEW_MODULES=$(
  IFS=','
  echo "${SELECTED[*]}"
)
if [[ -f "$ENV_FILE" ]]; then
  if grep -q '^MODULES=' "$ENV_FILE"; then
    sed -i "s/^MODULES=.*/MODULES=$NEW_MODULES/" "$ENV_FILE"
  else
    echo "MODULES=$NEW_MODULES" >> "$ENV_FILE"
  fi
else
  echo "MODULES=$NEW_MODULES" > "$ENV_FILE"
fi

# Determine which modules changed state and run installers or uninstallers.
new_set=" ${SELECTED[*]} "
for mod in "${AVAILABLE[@]}"; do
  currently=false
  [[ " ${ENABLED[*]} " == *" $mod "* ]] && currently=true
  target=false
  [[ "$new_set" == *" $mod "* ]] && target=true

  if $target && ! $currently; then
    [ -f "$ROOT_DIR/modules/$mod/install.sh" ] && "$ROOT_DIR/modules/$mod/install.sh"
  elif ! $target && $currently; then
    [ -f "$ROOT_DIR/modules/$mod/uninstall.sh" ] && "$ROOT_DIR/modules/$mod/uninstall.sh"
  fi
done
