#!/usr/bin/env bash
set -euo pipefail

REALM="pve"
ROLE="PVEAdmin"      # change as needed
PATH_IN_PVE="/"      # grant permissions at this path

# Ensure at least one username is provided
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <username1> [username2] [...]"
  exit 1
fi

# Check for pveum CLI
if ! command -v pveum &>/dev/null; then
  echo "ERROR: pveum CLI not found. Run this on a Proxmox VE host." >&2
  exit 1
fi

for u in "$@"; do
  echo "=== Processing user: $u ==="

  # 1) Create system user if missing
  if id "$u" &>/dev/null; then
    echo "System user '$u' exists; skipping."
  else
    echo "Creating system user '$u'..."
    useradd -m "$u"
  fi

  # 2) Set UNIX password
  echo "Set UNIX password for '$u':"
  passwd "$u"

  # 3) Add or update PVE user
  if pveum user list | grep -q "^$u@$REALM"; then
    echo "PVE user '$u@$REALM' exists; updating password..."
    pveum passwd "$u@$REALM"
  else
    echo "Adding PVE user '$u@$REALM'..."
    pveum user add "$u@$REALM" --comment "Created by script on $(date +%F)"
    echo "Set PVE password for '$u@$REALM':"
    pveum passwd "$u@$REALM"
  fi

  # 4) Assign role
  echo "Granting role '$ROLE' on '$PATH_IN_PVE' to '$u@$REALM'..."
  pveum acl modify "$PATH_IN_PVE" --user "$u@$REALM" --role "$ROLE" || \
    echo "Warning: could not modify ACL for $u@$REALM"

  echo
done

echo "Done. Users added/updated: $*"
