#!/usr/bin/env bash
# Manual install helper for the Omarchy Nostr Station plugin.
# Omarchy's plugin manager does not run install hooks, so this script is
# mainly for documentation and local debugging. Most users should simply:
#
#   omarchy plugin add https://github.com/jared-logan/omarchy-nostr-station.git --enable
#
# and then start Nostr Station from the Omarchy bar.

set -euo pipefail

echo "Installing nostr-station..."
curl -fsSL https://raw.githubusercontent.com/jared-logan/nostr-station/main/install.sh | bash

echo ""
echo "nostr-station installed. Enable the Omarchy plugin with:"
echo "  omarchy plugin add https://github.com/jared-logan/omarchy-nostr-station.git --enable"
