#!/usr/bin/env bash
# Install helper for the Omarchy Nostr Station plugin.
#
# Omarchy's plugin manager does not run install hooks, so this script is
# invoked by the plugin's Service.qml when the user first starts Nostr
# Station. It handles the Node version mismatch that can occur on Omarchy
# (default Node 26 is too new for the pinned better-sqlite3) by falling
# back to Node 22 via mise when needed.
#
# This script performs the same steps as nostr-station's upstream install.sh
# but does NOT auto-launch the dashboard — the Omarchy plugin controls that.

set -euo pipefail

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RESET='\033[0m'
log() { echo -e "${CYAN}▸${RESET} $*"; }
ok()  { echo -e "${GREEN}✓${RESET} $*"; }

REQUIRED_NODE=22
INSTALL_DIR="${HOME}/nostr-station"
REPO_URL="https://github.com/jared-logan/nostr-station.git"

# Omarchy ships Node 26 by default, but the pinned better-sqlite3 does not
# compile against it yet. Fall back to Node 22 via mise when needed.
CURRENT_MAJ=$(node -v 2>/dev/null | cut -d. -f1 | tr -d v || echo 0)
if [ "$CURRENT_MAJ" -ge 26 ]; then
  if command -v mise >/dev/null 2>&1; then
    log "Current Node is $CURRENT_MAJ; installing Node $REQUIRED_NODE via mise..."
    mise install "node@$REQUIRED_NODE" >/dev/null 2>&1 || true
    NODE22=$(mise where "node@$REQUIRED_NODE")
    export PATH="$NODE22/bin:$PATH"
    ok "Using Node $(node -v) for the install."
  else
    echo "Error: Node.js $REQUIRED_NODE+ is required, but the current Node is $CURRENT_MAJ and mise was not found." >&2
    echo "Install Node $REQUIRED_NODE first, then try again." >&2
    exit 1
  fi
fi

# 1 — OS guard
case "$(uname -s)" in
  Darwin|Linux) ;;
  *) echo "Unsupported OS: $(uname -s) — nostr-station only supports macOS and Linux." >&2; exit 1 ;;
esac

# 2 — git guard
if ! command -v git >/dev/null 2>&1; then
  echo "git is required." >&2
  exit 1
fi

# 3 — build toolchain guard
missing_build_tools=""
command -v make    >/dev/null 2>&1 || missing_build_tools+=" make"
command -v python3 >/dev/null 2>&1 || missing_build_tools+=" python3"
case "$(uname -s)" in
  Darwin)
    command -v clang++ >/dev/null 2>&1 || command -v c++ >/dev/null 2>&1 \
      || missing_build_tools+=" clang++"
    ;;
  Linux)
    command -v g++ >/dev/null 2>&1 || command -v c++ >/dev/null 2>&1 \
      || missing_build_tools+=" g++"
    ;;
esac
if [ -n "${missing_build_tools}" ]; then
  echo "Missing build tools:${missing_build_tools}" >&2
  exit 1
fi

# 4 — Node prerequisite
if [ "$(node -v | cut -d. -f1 | tr -d v)" -lt "$REQUIRED_NODE" ]; then
  echo "Node.js ${REQUIRED_NODE}+ is required." >&2
  exit 1
fi
ok "Node $(node --version) ready"

NPM_BIN="$(npm prefix -g)/bin"
export PATH="${NPM_BIN}:${PATH}"

# 5 — clone or update
if [ -d "${INSTALL_DIR}/.git" ]; then
  log "Updating existing checkout at ${INSTALL_DIR}…"
  git -C "${INSTALL_DIR}" fetch origin main --quiet
  git -C "${INSTALL_DIR}" merge --ff-only origin/main --quiet
elif [ -d "${INSTALL_DIR}" ]; then
  echo "Error: ${INSTALL_DIR} exists but isn't a git checkout." >&2
  exit 1
else
  log "Cloning nostr-station into ${INSTALL_DIR}…"
  git clone "${REPO_URL}" "${INSTALL_DIR}" --quiet
fi

cd "${INSTALL_DIR}"

log "Installing dependencies…"
npm ci --no-audit --no-fund

log "Building…"
npm run build --silent

if [ -f "${INSTALL_DIR}/bin/nostr-station.sh" ]; then
  chmod +x "${INSTALL_DIR}/bin/nostr-station.sh"
fi

log "Linking the nostr-station command globally…"
npm link --silent

ok "nostr-station installed at ${INSTALL_DIR}"
echo "Start it from the Omarchy bar."
