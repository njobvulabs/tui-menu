# AGENTS.md

Bash application (`tui-menu`): an fzf-based TUI launcher for terminal apps, aimed at
Arch Linux (`pacman`/`yay`). The main program is the single script `tui-menu`; the repo
also contains user and system installers, a desktop entry, and an SVG icon. There is no
build system, package manifest, test suite, lint config, or CI. `README.md` is
user-facing documentation, not the source of truth.

## Commands

- Syntax check: `bash -n tui-menu install.sh gui-install.sh`
- Desktop entry check: `desktop-file-validate tui-menu.desktop`
- Non-interactive smoke tests: `./tui-menu --help`, `./tui-menu --version`,
  `./tui-menu --list=all`, `./tui-menu --check`, `./tui-menu --check-config`
- Interactive run: `./tui-menu` (needs a TTY; uses `fzf`, or a numbered fallback menu
  if `fzf` is absent)
- Staged install test without touching the host:
  `tmp=$(mktemp -d); DESTDIR="$tmp/root" ./install.sh --prefix /usr`
- User install test without touching the real home:
  `tmp=$(mktemp -d); HOME="$tmp/home" XDG_DATA_HOME="$tmp/home/.local/share" ./gui-install.sh`
- `--check` exits `1` when any configured app is missing. This is expected behavior,
  not a broken test.
- `shellcheck` and `shfmt` are not installed here. Install them before relying on
  them; do not assume a lint step exists.

## Isolate state when testing

The script reads user state from:

- Config: `${XDG_CONFIG_HOME:-$HOME/.config}/tui-menu/apps.tsv`, overridable with
  `TUI_MENU_CONFIG`
- Cache: `${XDG_CACHE_HOME:-$HOME/.cache}/tui-menu/` (`history.tsv`, `sort-mode`,
  `show-missing`, `last-status`, `notice`)

Point both at temporary directories so tests do not mutate the user's menu:

```sh
tmp=$(mktemp -d)
XDG_CONFIG_HOME="$tmp/cfg" XDG_CACHE_HOME="$tmp/cache" ./tui-menu --list=all
```

Setting `TUI_MENU_CONFIG` suppresses creation of the default config; interactive mode
and `--_edit` call `ensure_config`, which creates it when the env var is unset.

## Architecture and gotchas

- Built-in entries live in `add_builtins()`. Config entries override a built-in by
  reusing the same command name; a leading `!` hides it (e.g. `!nano`). The config is
  only loaded if the file exists.
- Config format is TSV: `cmd<TAB>label<TAB>description<TAB>category<TAB>tags<TAB>package`.
  Only `cmd` is required; missing fields get defaults. `cmd_check_config` validates
  this file and exits `1` on warnings; keep its field rules in sync with `load_config`.
- Entries are keyed by the full command string, which may contain arguments. The
  executable/package default is `${cmd%% *}`. `add_app`'s optional seventh argument
  records `SOURCE` as `built-in` or `config`.
- Sort modes are `curated`, `frequent`, and `recent`; `history_sequence` reads
  `history.tsv`, and `history_stats` supplies preview launch counts/last-used times.
- `build_lines` emits `cmd<TAB>display<TAB>package<TAB>installed`; fzf uses
  `--accept-nth=1` and `{1}` for that command field. ANSI color is applied to the
  display field only.
- fzf bindings shell-call the script's internal subcommands: `--_list`, `--_preview`,
  `--_copy`, `--_launch`, `--_edit`, `--_toggle-sort`, `--_toggle-missing`,
  `--_header`, `--_footer`, `--_help`, `--_new-window`. Any new internal command needs
  a matching case in the dispatcher at the bottom of the script.
- `header_text` holds key hints; `footer_text` holds sort/missing state and installed
  counts. Both are refreshed via `transform-header`/`transform-footer` bindings.
- Color is gated by `color_enabled()`, honoring `NO_COLOR` and `TUI_MENU_COLOR=never`.
  Keep ANSI sequences out of the display field when color is disabled.
- Interactive `Enter` behavior depends on the `loop` argument: default mode loops back
  to the menu after the app exits; `--once` closes after launching.
- `tui-menu.desktop` is the source desktop entry. Keep `Exec=tui-menu` and
  `TryExec=tui-menu` in the template; `install.sh` rewrites both to the absolute
  installed binary path so GUI launchers do not depend on `~/.local/bin` being in PATH.
- `install.sh` defaults to `/usr/local`, supports `--prefix`, `--destdir`, and
  `--user`, and installs the binary, desktop entry, SVG icon, and PNG icon sizes when
  `rsvg-convert` is available. It uses `sudo` for system installs when needed.
- `gui-install.sh` is the per-user GUI installer; it calls `install.sh --user` and
  sends a `notify-send` notification. Keep its icon path in sync with the hicolor
  layout.
- Requires Bash 5+ (associative arrays, `mapfile`, `${var,,}`). Keep it Bash, not
  POSIX `sh`.
- `VERSION` is hardcoded near the top (`tui-menu:5`); bump it when releasing.
