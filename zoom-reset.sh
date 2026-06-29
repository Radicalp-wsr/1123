#!/bin/bash
#
# zoom-reset.sh — safely reset the Zoom client's LOCAL data on macOS.
#
# What it does (and ONLY this):
#   1. Quits Zoom
#   2. Backs up Zoom's local data to ~/Desktop/zoom-backup-<timestamp>/
#   3. Removes Zoom's local data (Zoom rebuilds it fresh on next launch)
#   4. Relaunches Zoom (unless --no-launch)
#
# What it deliberately does NOT do:
#   - No sudo / admin. No MAC-address spoofing. No firewall/network changes.
#   - No creating user accounts. Nothing that touches other apps.
# This is reversible local troubleshooting, not a Zoom-ban workaround.
#
# Usage:
#   ./zoom-reset.sh              # back up + reset + relaunch Zoom
#   ./zoom-reset.sh --no-launch  # reset but don't reopen Zoom
#   ./zoom-reset.sh --restore    # restore from the most recent backup
#
set -euo pipefail

# Zoom's local data paths (user-level only).
ZOOM_PATHS=(
  "$HOME/Library/Application Support/zoom.us"
  "$HOME/Library/Caches/us.zoom.xos"
  "$HOME/Library/Preferences/us.zoom.xos.plist"
  "$HOME/Library/Saved Application State/us.zoom.xos.savedState"
)

quit_zoom() {
  echo "[*] Quitting Zoom..."
  osascript -e 'quit app "zoom.us"' 2>/dev/null || true
  sleep 2
  killall "zoom.us" 2>/dev/null || true
}

do_reset() {
  if [ ! -d "/Applications/zoom.us.app" ]; then
    echo "[!] Zoom client not found in /Applications."
    echo "    Install it from https://zoom.us/download first, then re-run."
    exit 1
  fi

  quit_zoom

  local backup="$HOME/Desktop/zoom-backup-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$backup"
  local found=0
  echo "[*] Backing up to: $backup"
  for p in "${ZOOM_PATHS[@]}"; do
    if [ -e "$p" ]; then
      cp -R "$p" "$backup/" 2>/dev/null && { echo "    backed up: $p"; found=1; }
    fi
  done
  if [ "$found" -eq 0 ]; then
    echo "    (no existing Zoom data found — nothing to back up)"
    rmdir "$backup" 2>/dev/null || true
  fi

  echo "[*] Clearing Zoom local data..."
  for p in "${ZOOM_PATHS[@]}"; do
    rm -rf "$p" 2>/dev/null || true
  done
  rm -rf "$HOME/Library/Logs/zoom.us.log"* 2>/dev/null || true
  defaults delete us.zoom.xos 2>/dev/null || true
  echo "[+] Zoom local data cleared. You'll need to sign in again."

  if [ "${1:-}" != "--no-launch" ]; then
    echo "[*] Relaunching Zoom..."
    open -a "zoom.us" 2>/dev/null || echo "[!] Could not open Zoom; launch it manually."
  fi
}

do_restore() {
  local latest
  latest=$(ls -dt "$HOME"/Desktop/zoom-backup-* 2>/dev/null | head -1 || true)
  if [ -z "$latest" ]; then
    echo "[!] No backup folder found on the Desktop. Nothing to restore."
    exit 1
  fi
  echo "[*] Restoring from: $latest"
  quit_zoom
  shopt -s dotglob nullglob
  for item in "$latest"/*; do
    local name dest
    name=$(basename "$item")
    case "$name" in
      "zoom.us")                       dest="$HOME/Library/Application Support/$name" ;;
      "us.zoom.xos")                   dest="$HOME/Library/Caches/$name" ;;
      "us.zoom.xos.plist")             dest="$HOME/Library/Preferences/$name" ;;
      "us.zoom.xos.savedState")        dest="$HOME/Library/Saved Application State/$name" ;;
      *) echo "    skipping unknown item: $name"; continue ;;
    esac
    rm -rf "$dest" 2>/dev/null || true
    cp -R "$item" "$dest" && echo "    restored: $dest"
  done
  echo "[+] Restore complete."
}

case "${1:-}" in
  --restore) do_restore ;;
  --no-launch) do_reset --no-launch ;;
  "" ) do_reset ;;
  *) echo "Usage: $0 [--no-launch | --restore]"; exit 2 ;;
esac
