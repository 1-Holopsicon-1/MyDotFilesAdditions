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

setup_booru_creds() {
    # Provider credentials: entered once per machine, stored locally (never in the repo)
    local creds_dir="${HOME}/.config/illogical-impulse"
    local creds_file="${creds_dir}/booru-creds.json"

    if [[ -f "${creds_file}" ]]; then
        echo "[ii-custom] Creds already present: ${creds_file} (delete the file to re-enter)"
        return 0
    fi

    if [[ ! -t 0 ]]; then
        echo "[ii-custom] INFO: no interactive terminal — provider creds entry skipped"
        return 0
    fi

    mkdir -p "${creds_dir}"
    echo "[ii-custom] Provider credentials (stored only on this machine, never committed)."
    echo "[ii-custom] Press Enter to skip a field — posts search will work anonymously."
    read -r -p "[ii-custom] rule34 api key: " api_key
    read -r -p "[ii-custom] rule34 user id: " user_id

    if [[ -z "${api_key}" && -z "${user_id}" ]]; then
        echo "[ii-custom] No creds provided, file not created"
        return 0
    fi

    python3 - "${creds_file}" "${api_key}" "${user_id}" <<'PY'
import json, os, sys

path, api_key, user_id = sys.argv[1], sys.argv[2], sys.argv[3]
data = {}
if api_key or user_id:
    data["rule34"] = {}
if api_key:
    data["rule34"]["apiKey"] = api_key
if user_id:
    data["rule34"]["userId"] = user_id
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=4, ensure_ascii=False)
    f.write("\n")
os.chmod(path, 0o600)
PY
    echo "[ii-custom] Creds written to ${creds_file}"
}

setup_booru_creds

if [[ -f "${SHELL_ENTRY}" ]]; then
    touch "${SHELL_ENTRY}"
    echo "[ii-custom] Quickshell reload requested"
fi
