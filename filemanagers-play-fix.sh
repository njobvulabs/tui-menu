#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

OPENER="$HOME/.config/nnn/opener.sh"
YAZI_CONF="$HOME/.config/yazi/yazi.toml"
SUPERFILE_CONF="$HOME/.config/superfile/config.toml"
BASHRC="$HOME/.bashrc"

mkdir -p "$HOME/.config/nnn" "$HOME/.config/yazi" "$HOME/.config/superfile"

install_nnn_opener() {
  cat > "$OPENER" <<'EOF'
#!/bin/sh
nohup mpv "$1" </dev/tty >/dev/null 2>&1 &
EOF
  chmod 0755 "$OPENER"
}

ensure_bashrc_export() {
  local name=$1 value=$2
  if ! grep -q "^export ${name}=" "$BASHRC"; then
    printf '\n# tui-menu: media play fix\nexport %s=%s\n' "$name" "$value" >> "$BASHRC"
  fi
}

write_yazi_conf() {
  cat > "$YAZI_CONF" <<'EOF'
#:schema https://yazi-rs.github.io/schemas/yazi.json

[mgr]
ratio          = [ 1, 4, 3 ]
sort_by        = "alphabetical"
sort_sensitive = false
sort_reverse 	 = false
sort_dir_first = true
sort_translit  = false
sort_fallback  = "alphabetical"
linemode       = "none"
show_hidden    = false
show_symlink   = true
scrolloff      = 5
mouse_events   = [ "click", "scroll", "drag" ]

[preview]
wrap            = "no"
tab_size        = 2
max_width       = 600
max_height      = 900
cache_dir       = ""
image_delay     = 30
image_filter    = "triangle"
image_quality   = 75
ueberzug_scale  = 1
ueberzug_offset = [ 0, 0, 0, 0 ]

[opener]
edit = [
	{ run = "${EDITOR:-vi} %s", desc = "$EDITOR",      for = "unix", block = true },
	{ run = "code %s",          desc = "code",         for = "windows", orphan = true },
	{ run = "code -w %s",       desc = "code (block)", for = "windows", block = true },
]
play = [
	{ run = "mpv %s1",    desc = "Play", for = "linux", block = true },
	{ run = "open %s",         desc = "Play", for = "macos" },
	{ run = 'start "" %s1',    desc = "Play", for = "windows", orphan = true },
	{ run = "termux-open %s1", desc = "Play", for = "android" },
	{ run = "mediainfo %s1; echo 'Press enter to exit'; read _", block = true, desc = "Show media info", for = "unix" },
	{ run = "mediainfo %s1 & pause", block = true, desc = "Show media info", for = "windows" },
]
open = [
	{ run = "xdg-open %s1",    desc = "Open", for = "linux" },
	{ run = "open %s",         desc = "Open", for = "macos" },
	{ run = 'start "" %s1',    desc = "Open", for = "windows", orphan = true },
	{ run = "termux-open %s1", desc = "Open", for = "android" },
]
reveal = [
	{ run = "xdg-open %d1",         desc = "Reveal", for = "linux" },
	{ run = "open -R %s1",          desc = "Reveal", for = "macos" },
	{ run = "explorer /select,%s1", desc = "Reveal", for = "windows", orphan = true },
	{ run = "termux-open %d1",      desc = "Reveal", for = "android" },
	{ run = "clear; exiftool %s1; echo 'Press enter to exit'; read _", desc = "Show EXIF", for = "unix", block = true },
]
extract = [
	{ run = "ya pub extract --list %s", desc = "Extract here" },
]
download = [
	{ run = "ya emit download --open %S", desc = "Download and open" },
	{ run = "ya emit download %S",        desc = "Download" },
]
trash = [
	{ run = "ya pub trash-restore --list %S", desc = "Restore selected files" },
	{ run = "ya pub trash-empty --list %S",   desc = "Empty trash bin" },
]

[open]
rules = [
	{ mime = "folder/*", use = [ "edit", "open", "reveal" ] },
	{ mime = "text/*", use = [ "edit", "reveal" ] },
	{ mime = "image/*", use = [ "open", "reveal" ] },
	{ mime = "{audio,video}/*", use = [ "play", "reveal" ] },
	{ mime = "application/{json,ndjson,javascript,wine-extension-ini}", use = [ "edit", "reveal" ] },
	{ mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,lzma,compress,archive,cpio,arj,xar,ms-cab*}", use = [ "extract", "reveal" ] },
	{ mime = "inode/empty", use = [ "edit", "reveal" ] },
	{ mime = "vfs/{absent,stale}", use = "download" },
	{ mime = "trash/**", use = [ "open", "trash" ] },
	{ url = "*", use = [ "open", "reveal" ] },
]

[tasks]
file_workers     = 3
plugin_workers   = 5
fetch_workers    = 5
preload_workers  = 2
process_workers  = 5
image_alloc      = 536870912  # 512MB
image_bound      = [ 10000, 10000 ]
suppress_preload = false

[plugin]
fetchers = [
	{ url = "*/",         run = "mime.dir",    prio = "high", group = "mime" },
	{ url = "local://*",  run = "mime.local",  prio = "high", group = "mime" },
	{ url = "trash://*",  run = "mime.trash",  prio = "high", group = "mime" },
	{ url = "remote://*", run = "mime.remote", prio = "high", group = "mime" },
]
spotters = [
	{ mime = "multi/*", run = "multi" },
	{ mime = "folder/*", run = "folder" },
	{ mime = "text/*", run = "code" },
	{ mime = "application/{mbox,javascript,wine-extension-ini}", run = "code" },
	{ mime = "image/{avif,hei?,jxl}", run = "magick" },
	{ mime = "image/svg+xml", run = "svg" },
	{ mime = "image/*", run = "image" },
	{ mime = "video/*", run = "video" },
	{ mime = "vfs/*", run = "vfs" },
	{ mime = "trash/**", run = "trash" },
	{ mime = "error/*", run = "error" },
	{ url = "*", run = "file" },
	{ url = "*/", run = "file" },
]
preloaders = [
	{ mime = "image/{avif,hei?,jxl}", run = "magick" },
	{ mime = "image/svg+xml", run = "svg" },
	{ mime = "image/*", run = "image" },
	{ mime = "video/*", run = "video" },
	{ mime = "application/pdf", run = "pdf" },
	{ mime = "font/*", run = "font" },
	{ mime = "application/ms-opentype", run = "font" },
	{ mime = "trash/**", run = "trash" },
]
previewers = [
	{ mime = "folder/*", run = "folder" },
	{ mime = "text/*", run = "code" },
	{ mime = "application/{mbox,javascript,wine-extension-ini}", run = "code" },
	{ mime = "application/json", run = "json" },
	{ mime = "application/{json,ndjson}", run = "json" },
	{ mime = "image/{avif,hei?,jxl}", run = "magick" },
	{ mime = "image/svg+xml", run = "svg" },
	{ mime = "image/*", run = "image" },
	{ mime = "video/*", run = "video" },
	{ mime = "application/pdf", run = "pdf" },
	{ mime = "archive", run = "archive" },
	{ mime = "font/*", run = "font" },
	{ mime = "application/ms-opentype", run = "font" },
	{ mime = "empty", run = "empty" },
	{ mime = "vfs/*", run = "vfs" },
	{ mime = "trash/**", run = "trash" },
	{ mime = "error/*", run = "error" },
	{ url = "*", run = "file" },
]

[input]
cursor_blink = false

# cd
cd_title  = "Change directory:"
cd_origin = "top-center"
cd_offset = [ 0, 2, 80, 3 ]

# create
create_title  = [ "Create:", "Create (dir):" ]
create_origin = "top-center"
create_offset = [ 0, 2, 80, 3 ]

# rename
rename_title  = "Rename:"
rename_origin = "hovered"
rename_offset = [ 0, 1, 80, 3 ]

# filter
filter_title  = "Filter:"
filter_origin = "top-center"
filter_offset = [ 0, 2, 80, 3 ]

# find
find_title  = [ "Find next:", "Find previous:" ]
find_origin = "top-center"
find_offset = [ 0, 2, 80, 3 ]

# shell
shell_title  = [ "Shell:", "Shell (block):" ]
shell_origin = "top-center"
shell_offset = [ 0, 2, 80, 3 ]

[confirm]
trash_title 	= "Trash {n} selected file{s}?"
trash_origin	= "center"
trash_offset	= [ 0, 0, 70, 20 ]
delete_title 	= "Permanently delete {n} selected file{s}?"
delete_origin	= "center"
delete_offset	= [ 0, 0, 50, 15 ]
overwrite_title = "Overwrite file?"
overwrite_body   = "Will overwrite the following file:"
overwrite_origin = "center"
overwrite_offset = [ 0, 0, 50, 15 ]
quit_title  = "Quit?"
quit_body   = "There are unfinished tasks, quit anyway?\n(Open task manager with default key 'w)"
quit_origin = "center"
quit_offset = [ 0, 0, 50, 20 ]

[pick]
open_title  = "Open with:"
open_origin = "hovered"
open_offset = [ 0, 1, 50, 7 ]

[which]
sort_by      	 = "none"
sort_sensitive = false
sort_reverse 	 = false
sort_translit  = false
EOF
}

install_superfile_open_with() {
  if grep -q '^mp4 = "mpv"' "$SUPERFILE_CONF"; then
    return 0
  fi
  cat >> "$SUPERFILE_CONF" <<'EOF'

[open_with]
mp4 = "mpv"
mkv = "mpv"
mov = "mpv"
avi = "mpv"
wmv = "mpv"
flv = "mpv"
webm = "mpv"
mpg = "mpv"
mpeg = "mpv"
m4v = "mpv"
ts = "mpv"
m2ts = "mpv"
mp3 = "mpv"
flac = "mpv"
wav = "mpv"
aac = "mpv"
ogg = "mpv"
opus = "mpv"
m4a = "mpv"
wma = "mpv"
aiff = "mpv"
alac = "mpv"
EOF
}

main() {
  install_nnn_opener
  ensure_bashrc_export NNN_OPENER "$OPENER"
  ensure_bashrc_export MC_XDG_OPEN "mpv"
  write_yazi_conf
  install_superfile_open_with
}

main "$@"
