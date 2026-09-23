#!/usr/bin/env bash
# Install helper for the Omarchy Nostr Station plugin.
#
# Omarchy's plugin manager does not run install hooks, so this script is
# invoked by the plugin's Service.qml when the user first starts Nostr
# Station. It handles the Node version mismatch that can occur on Omarchy
# (default Node 26 is too new for the pinned better-sqlite3) by falling
# back to Node 22 via mise when needed.

set -euo pipefail

REQUIRED_NODE=22
CURRENT_MAJ=$(node -v 2>/dev/null | cut -d. -f1 | tr -d v || echo 0)

if [ "$CURRENT_MAJ" -ge 26 ]; then
  if command -v mise >/dev/null 2>&1; then
    echo "Current Node is $CURRENT_MAJ; installing Node $REQUIRED_NODE via mise..."
    mise install "node@$REQUIRED_NODE" >/dev/null 2>&1 || true
    NODE22=$(mise where "node@$REQUIRED_NODE")
    export PATH="$NODE22/bin:$PATH"
    echo "Using Node $(node -v) for the install."
  else
    echo "Error: Node.js $REQUIRED_NODE+ is required, but the current Node is $CURRENT_MAJ and mise was not found." >&2
    echo "Install Node $REQUIRED_NODE first, then try again." >&2
    exit 1
  fi
fi

echo "Installing nostr-station..."
curl -fsSL https://raw.githubusercontent.com/jared-logan/nostr-station/main/install.sh | bash

echo ""
echo "nostr-station installed. You can now start it from the Omarchy bar."
