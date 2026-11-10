#!/usr/bin/env bash
# Update end-4/dots-hyprland with user overrides preserved.

set -uo pipefail

# Ensure standard XDG directories are exported for envsubst in setup scripts
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"

REPO_DIR="${HOME}/.cache/dots-hyprland"
EXP_YAML_MINE="${HOME}/hypr-dots/3.files-exp.yaml.mine"
EXP_YAML_TARGET="${REPO_DIR}/sdata/subcmd-install/3.files-exp.yaml"
BACKUP_DIR="${HOME}/hypr-dots/config-backup-$(date +%Y%m%d-%H%M%S)"
MICROTEX_DIR="${REPO_DIR}/sdata/dist-arch/illogical-impulse-microtex-git"

echo "[hypr-dots-update] Updating dots-hyprland..."

# Backup current config before update
echo "[hypr-dots-update] Creating backup at ${BACKUP_DIR}..."
mkdir -p "${BACKUP_DIR}"
cp -a "${HOME}/.config" "${BACKUP_DIR}/"

# Update repo
echo "[hypr-dots-update] Pulling latest changes..."
cd "${REPO_DIR}"
git pull

# Apply custom exp-files config
echo "[hypr-dots-update] Applying custom 3.files-exp.yaml..."
cp "${EXP_YAML_MINE}" "${EXP_YAML_TARGET}"

# Pre-emptively fix MicroTeX clone if it is not a proper clone
if [[ -d "${MICROTEX_DIR}/MicroTeX" ]]; then
    echo "[hypr-dots-update] Checking MicroTeX clone validity..."
    if ! git -C "${MICROTEX_DIR}/MicroTeX" remote -v 2>/dev/null | grep -q "github.com/end-4/MicroTeX.git"; then
        echo "[hypr-dots-update] MicroTeX is not a valid clone, removing cached source..."
        rm -rf "${MICROTEX_DIR}/MicroTeX" "${MICROTEX_DIR}/src"
    fi
fi

# Run setup
echo "[hypr-dots-update] Running ./setup install --exp-files -f --skip-allgreeting --skip-backup..."
if ./setup install --exp-files -f --skip-allgreeting --skip-backup; then
    echo "[hypr-dots-update] Done."

    # Re-apply custom quickshell modules (KeyboardLayoutOsd, LockClock) —
    # code lives in this repo as stow package "ii-custom"; this restores
    # the small integration snippets the updater overwrote
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "[hypr-dots-update] Re-applying ii-custom quickshell modules..."
    if [[ -x "${SCRIPT_DIR}/reapply-custom.sh" ]]; then
        "${SCRIPT_DIR}/reapply-custom.sh" || echo "[hypr-dots-update] Warning: reapply had errors"
    else
        echo "[hypr-dots-update] Warning: reapply-custom.sh not found next to update.sh, skipped"
    fi
else
    echo "[hypr-dots-update] Setup failed. Common cause: MicroTeX needs manual rebuild/install due to sudo."
    echo "[hypr-dots-update] Try running:"
    echo "  cd ${MICROTEX_DIR}"
    echo "  rm -rf MicroTeX src pkg *.pkg.tar.zst"
    echo "  makepkg -si"
    echo "[hypr-dots-update] Then re-run: hypr-dots-update"
    exit 1
fi

echo "[hypr-dots-update] Backup saved to: ${BACKUP_DIR}"
