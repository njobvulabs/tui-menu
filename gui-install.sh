#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ICON_PATH=${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/scalable/apps/tui-menu.svg

notify() {
  local summary=$1 message=$2
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "TUI Menu" -i "$ICON_PATH" "$summary" "$message" >/dev/null 2>&1 || true
  fi
}

if ! bash "$SCRIPT_DIR/install.sh" --user; then
  notify "TUI Menu installation failed" "Run gui-install.sh from a terminal for details."
  exit 1
fi

notify "TUI Menu installed" "Search for \"TUI Menu\" in your application menu."
