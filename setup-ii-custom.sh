#!/usr/bin/env bash
# Deploys ii-custom quickshell modules on this machine (idempotent).
# Source of truth: this repository — stow package "ii-custom".
# Runtime: ~/.local/share/ii-custom/qs-modules becomes a symlink into the repo.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="${HOME}/.local/share/ii-custom"
SHELL_ENTRY="${HOME}/.config/quickshell/ii/shell.qml"

command -v stow >/dev/null || {
    echo "[ii-custom] GNU stow not found. Install it first: sudo pacman -S stow"
    exit 1
}

# Migrate stale pre-stow runtime layout (was a real dir duplicating repo files)
if [[ -e "${RUNTIME_DIR}" && ! -L "${RUNTIME_DIR}" ]]; then
    if [[ -d "${RUNTIME_DIR}/qs-modules" && ! -e "${RUNTIME_DIR}/reapply-custom.sh" ]]; then
        echo "[ii-custom] Removing stale pre-stow runtime dir ${RUNTIME_DIR} (source files live in this repo)"
        rm -rf "${RUNTIME_DIR}"
    else
        echo "[ii-custom] ERROR: ${RUNTIME_DIR} exists with unknown content;"
        echo "[ii-custom] move it away manually, then re-run this script."
        exit 1
    fi
fi

stow -R -t "${HOME}" -d "${REPO_DIR}" ii-custom
echo "[ii-custom] Stowed: ${RUNTIME_DIR}/qs-modules -> $(readlink -f "${RUNTIME_DIR}/qs-modules")"

"${REPO_DIR}/reapply-custom.sh"

if [[ -f "${SHELL_ENTRY}" ]]; then
    touch "${SHELL_ENTRY}"
    echo "[ii-custom] Quickshell reload requested"
fi
