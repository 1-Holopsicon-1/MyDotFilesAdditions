#!/usr/bin/env bash
# Deploys ii-custom quickshell modules on this machine (idempotent).
# Source of truth: this repository — stow package "ii-custom".
# Runtime: ~/.local/share/ii-custom/qs-modules becomes a symlink into the repo.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="${HOME}/.local/share/ii-custom"
SHELL_ENTRY="${HOME}/.config/quickshell/ii/shell.qml"

# Ensure GNU stow is available, installing it if missing
if ! command -v stow >/dev/null 2>&1; then
    echo "[ii-custom] GNU stow not found, installing..."
    if command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm stow || {
            echo "[ii-custom] ERROR: pacman failed to install stow (password/rights issue?)"
            exit 1
        }
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y stow || { echo "[ii-custom] ERROR: apt failed to install stow"; exit 1; }
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y stow || { echo "[ii-custom] ERROR: dnf failed to install stow"; exit 1; }
    else
        echo "[ii-custom] ERROR: no known package manager (pacman/apt/dnf); install GNU stow manually"
        exit 1
    fi
fi
echo "[ii-custom] stow: $(stow --version | head -1)"

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
