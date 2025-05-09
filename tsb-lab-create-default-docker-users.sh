#!/bin/bash

set -e

echo "🔧 Creating users: ondra and vojta"

for user in ondra vojta; do
  if id "$user" &>/dev/null; then
    echo "✅ User $user already exists, skipping..."
  else
    echo "➕ Creating user $user..."
    adduser --gecos "" "$user"
    usermod -aG docker "$user"
    usermod -aG sudo "$user"
  fi
done

echo -e "\n👥 Group memberships:"
for user in ondra vojta; do
  echo "   $user: $(id -nG $user)"
done

echo -e "\n✅ All done. Users are ready to use Docker and sudo."
