#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <username> <pubkey_file>" >&2
  exit 1
fi

username="$1"
pubkey="$2"

: "${UNIX_PROVISION_ALLOWED?need UNIX_PROVISION_ALLOWED}"
: "${UNIX_DEFAULT_GROUP?need UNIX_DEFAULT_GROUP}"
: "${UNIX_HOME_BASE?need UNIX_HOME_BASE}"

if [[ "$UNIX_PROVISION_ALLOWED" != "1" ]]; then
  echo "provisioning disabled" >&2
  exit 1
fi

if [[ ! -f "$pubkey" ]]; then
  echo "public key file not found" >&2
  exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
"$script_dir/check_username.sh" "$username"

if ! getent group "$UNIX_DEFAULT_GROUP" > /dev/null; then
  echo "group $UNIX_DEFAULT_GROUP not found" >&2
  exit 1
fi

home_dir="$UNIX_HOME_BASE/$username"
mkdir -p "$UNIX_HOME_BASE"
useradd -d "$home_dir" -g "$UNIX_DEFAULT_GROUP" -m -s /bin/bash "$username"

install -d -m 700 -o "$username" -g "$UNIX_DEFAULT_GROUP" "$home_dir/.ssh"
install -m 600 -o "$username" -g "$UNIX_DEFAULT_GROUP" "$pubkey" "$home_dir/.ssh/authorized_keys"

echo "provisioned $username"
