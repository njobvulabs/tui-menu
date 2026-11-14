#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROG=$(basename -- "$0")

usage() {
  cat <<EOF
Usage: $PROG [--user] [--prefix DIR] [--destdir DIR]

Install tui-menu, its desktop launcher, and its icon.

  --user          Install for the current user (~/.local)
  --prefix DIR    Installation prefix (default: /usr/local)
  --destdir DIR   Staging directory for packaging (default: empty)
  -h, --help      Show this help

Environment overrides: PREFIX, DESTDIR, BINDIR, DATADIR, APPSDIR, ICONBASE
EOF
}

USER_INSTALL=0
PREFIX_ARG=
DESTDIR_ARG=

while (($#)); do
  case $1 in
    --user) USER_INSTALL=1 ;;
    --prefix)
      [[ $# -ge 2 ]] || { echo "$PROG: --prefix requires a directory" >&2; exit 2; }
      PREFIX_ARG=$2
      shift
      ;;
    --prefix=*) PREFIX_ARG=${1#*=} ;;
    --destdir)
      [[ $# -ge 2 ]] || { echo "$PROG: --destdir requires a directory" >&2; exit 2; }
      DESTDIR_ARG=$2
      shift
      ;;
    --destdir=*) DESTDIR_ARG=${1#*=} ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "$PROG: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if (( USER_INSTALL )); then
  : "${HOME:?HOME must be set when using --user}"
  PREFIX=${PREFIX_ARG:-$HOME/.local}
  DATADIR=${DATADIR:-${XDG_DATA_HOME:-$HOME/.local/share}}
else
  PREFIX=${PREFIX_ARG:-${PREFIX:-/usr/local}}
  DATADIR=${DATADIR:-$PREFIX/share}
fi

BINDIR=${BINDIR:-$PREFIX/bin}
APPSDIR=${APPSDIR:-$DATADIR/applications}
ICONBASE=${ICONBASE:-$DATADIR/icons/hicolor}
DESTDIR=${DESTDIR_ARG:-${DESTDIR:-}}
DESTDIR=${DESTDIR%/}

for dir in "$BINDIR" "$APPSDIR" "$ICONBASE"; do
  [[ $dir == /* ]] || { echo "$PROG: install paths must be absolute: $dir" >&2; exit 2; }
done

for file in tui-menu tui-menu.desktop tui-menu.svg; do
  [[ -f $SCRIPT_DIR/$file ]] || { echo "$PROG: missing required file: $SCRIPT_DIR/$file" >&2; exit 1; }
done

SUDO=
if (( ! USER_INSTALL )) && [[ -z $DESTDIR ]] && (( EUID != 0 )); then
  if command -v sudo >/dev/null 2>&1; then
    SUDO=sudo
  else
    echo "$PROG: run as root or install sudo to perform a system-wide install" >&2
    exit 1
  fi
fi

run() {
  if [[ -n $SUDO ]]; then
    sudo "$@"
  else
    "$@"
  fi
}

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

exec_path=$BINDIR/tui-menu
awk -v exec_path="$exec_path" '
  /^Exec=/    { print "Exec=\"" exec_path "\""; next }
  /^TryExec=/ { print "TryExec=" exec_path; next }
  { print }
' "$SCRIPT_DIR/tui-menu.desktop" > "$TMP_DIR/tui-menu.desktop"

if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate "$TMP_DIR/tui-menu.desktop"
fi

run install -Dm755 "$SCRIPT_DIR/tui-menu" "${DESTDIR}${BINDIR}/tui-menu"
run install -Dm644 "$TMP_DIR/tui-menu.desktop" "${DESTDIR}${APPSDIR}/tui-menu.desktop"
run install -Dm644 "$SCRIPT_DIR/tui-menu.svg" "${DESTDIR}${ICONBASE}/scalable/apps/tui-menu.svg"

if command -v rsvg-convert >/dev/null 2>&1; then
  for size in 16 24 32 48 64 128 256; do
    png="$TMP_DIR/tui-menu-${size}.png"
    rsvg-convert -w "$size" -h "$size" "$SCRIPT_DIR/tui-menu.svg" -o "$png"
    run install -Dm644 "$png" "${DESTDIR}${ICONBASE}/${size}x${size}/apps/tui-menu.png"
  done
fi

if [[ -z $DESTDIR ]]; then
  if command -v update-desktop-database >/dev/null 2>&1; then
    run update-desktop-database "$APPSDIR" >/dev/null 2>&1 || true
  fi
  if command -v gtk-update-icon-cache >/dev/null 2>&1 && [[ -f "$ICONBASE/index.theme" ]]; then
    run gtk-update-icon-cache -f -t "$ICONBASE" >/dev/null 2>&1 || true
  fi
fi

if ! command -v fzf >/dev/null 2>&1; then
  echo "Note: fzf is not installed; tui-menu will use its numbered fallback menu." >&2
fi

echo "Installed tui-menu:"
echo "  binary:  ${DESTDIR}${BINDIR}/tui-menu"
echo "  desktop: ${DESTDIR}${APPSDIR}/tui-menu.desktop"
echo "  icon:    ${DESTDIR}${ICONBASE}/scalable/apps/tui-menu.svg"
if (( USER_INSTALL )); then
  echo 'Open your application menu and search for "TUI Menu".'
fi
