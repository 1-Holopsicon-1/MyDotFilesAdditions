#!/usr/bin/env bash
# Re-applies integration of external quickshell modules (ii-custom) after a
# dotfiles update has overwritten illogical-impulse files.
#
# Layout: this script lives in the hypr-dots repo next to update.sh.
# Module code lives in the stow package  ./ii-custom/.local/share/ii-custom/qs-modules/
# (stowed at setup time into ~/.local/share/ii-custom/qs-modules — see
# setup-ii-custom.sh). Integration lines are re-inserted into freshly updated
# illogical-impulse files. Idempotent: run as often as needed.

set -uo pipefail

HOST_HOME="${HOME}"
CUSTOM_MODULES="${HOST_HOME}/.local/share/ii-custom/qs-modules"
II_DIR="${HOST_HOME}/.config/quickshell/ii"
RESTORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/restore"

fail() { echo "[ii-custom] ERROR: $1"; exit 1; }

[[ -d "${II_DIR}" ]] || fail "${II_DIR} not found (is illogical-impulse dotfiles installed?)"
[[ -d "${CUSTOM_MODULES}" ]] || fail "${CUSTOM_MODULES} not found (run ./setup-ii-custom.sh first?)"

apply_family() {
    local f="${II_DIR}/panelFamilies/IllogicalImpulseFamily.qml"
    [[ -f "$f" ]] || { echo "[ii-custom] SKIP: $f missing (upstream layout changed?)"; return 0; }

    python3 - "$f" "${CUSTOM_MODULES}" <<'PY'
import sys

path, custom_modules = sys.argv[1], sys.argv[2]
needle_import = f'import "file:{custom_modules}"'
anchor_import = "import qs.modules.ii.wallpaperSelector"
needle_loader = "PanelLoader { component: KeyboardLayoutOsd {} }"
anchor_loader = "    PanelLoader { component: OnScreenDisplay {} }"

s = open(path, encoding="utf-8").read()
touched = False

if needle_import not in s:
    if anchor_import not in s:
        print("[ii-custom] SKIP: import anchor missing in IllogicalImpulseFamily.qml (upstream changed?)")
    else:
        s = s.replace(anchor_import, anchor_import + "\n" + needle_import, 1)
        touched = True
        print("[ii-custom] Added external import to IllogicalImpulseFamily.qml")

if needle_loader not in s:
    if anchor_loader not in s:
        print("[ii-custom] SKIP: PanelLoader anchor missing in IllogicalImpulseFamily.qml (upstream changed?)")
    else:
        s = s.replace(anchor_loader, anchor_loader + "\n" + needle_loader, 1)
        touched = True
        print("[ii-custom] Registered KeyboardLayoutOsd in IllogicalImpulseFamily.qml")

if touched:
    open(path, "w", encoding="utf-8").write(s)
    print("[ii-custom] Saved IllogicalImpulseFamily.qml")
else:
    print("[ii-custom] OK: IllogicalImpulseFamily.qml already integrated")
PY
}

apply_lock() {
    local f="${II_DIR}/modules/ii/lock/LockSurface.qml"
    [[ -f "$f" ]] || { echo "[ii-custom] SKIP: $f missing (upstream layout changed?)"; return 0; }

    python3 - "$f" "${CUSTOM_MODULES}" <<'PY'
import sys

path, custom_modules = sys.argv[1], sys.argv[2]
needle_import = f'import "file:{custom_modules}"'
anchor_import = "import Quickshell.Services.SystemTray"
needle_clock = "LockClock {"
anchor_clock = "    // Main toolbar: password box"
clock_block = "    // Lock clock\n    LockClock {}\n\n"

s = open(path, encoding="utf-8").read()
touched = False

if needle_import not in s:
    if anchor_import not in s:
        print("[ii-custom] SKIP: import anchor missing in LockSurface.qml (upstream changed?)")
    else:
        s = s.replace(anchor_import, anchor_import + "\n" + needle_import, 1)
        touched = True
        print("[ii-custom] Added external import to LockSurface.qml")

if needle_clock not in s:
    if anchor_clock not in s:
        print("[ii-custom] SKIP: lock clock anchor missing in LockSurface.qml (upstream changed?)")
    else:
        s = s.replace(anchor_clock, clock_block + anchor_clock, 1)
        touched = True
        print("[ii-custom] Re-added LockClock to LockSurface.qml")

if touched:
    open(path, "w", encoding="utf-8").write(s)
    print("[ii-custom] Saved LockSurface.qml")
else:
    print("[ii-custom] OK: LockSurface.qml already integrated")
PY
}

apply_booru() {
    # Whole-file restoration for heavily customized ii files (wallpaper search).
    # Wipe detection: live copy compared against the upstream clone reference.
    local custom="${RESTORE_DIR}/Booru.qml"
    local live="${II_DIR}/services/Booru.qml"
    local upstream="${HOST_HOME}/.cache/dots-hyprland/dots/.config/quickshell/ii/services/Booru.qml"

    [[ -f "${custom}" ]] || { echo "[ii-custom] SKIP: ${custom} missing"; return 0; }
    [[ -f "${live}" ]] || { echo "[ii-custom] SKIP: ${live} missing (upstream layout changed?)"; return 0; }

    if cmp -s "${live}" "${custom}"; then
        echo "[ii-custom] OK: Booru.qml already customized"
        return 0
    fi

    if [[ -f "${upstream}" ]] && cmp -s "${live}" "${upstream}"; then
        cp "${custom}" "${live}"
        echo "[ii-custom] Restored Booru.qml customization (update wiped it)"
        return 0
    fi

    echo "[ii-custom] SKIP: Booru.qml diverged from both repo copy and upstream reference — manual merge needed"
    echo "[ii-custom]   live:     ${live}"
    echo "[ii-custom]   repo:     ${custom}"
    echo "[ii-custom]   upstream: ${upstream}"
}

echo "[ii-custom] Re-applying external quickshell modules..."
apply_family
apply_lock
apply_booru
echo "[ii-custom] Done. If the shell is running, reload it: touch ~/.config/quickshell/ii/shell.qml"
