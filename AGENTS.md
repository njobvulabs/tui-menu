# AGENTS.md

Single-file Bash application (`tui-menu`): an fzf-based TUI launcher for terminal apps,
aimed at Arch Linux (`pacman`/`yay`). There is no README, build system, package
manifest, test suite, lint config, or CI. The script `tui-menu` is the entire project.

## Commands

- Syntax check: `bash -n tui-menu`
- Non-interactive smoke tests: `./tui-menu --help`, `./tui-menu --version`,
  `./tui-menu --list=all`, `./tui-menu --check`
- Interactive run: `./tui-menu` (needs a TTY; uses `fzf`, or a numbered fallback menu
  if `fzf` is absent)
- `--check` exits `1` when any configured app is missing. This is expected behavior,
  not a broken test.
- `shellcheck` and `shfmt` are not installed here. Install them before relying on
  them; do not assume a lint step exists.

## Isolate state when testing

The script reads user state from:

- Config: `${XDG_CONFIG_HOME:-$HOME/.config}/tui-menu/apps.tsv`, overridable with
  `TUI_MENU_CONFIG`
- Cache: `${XDG_CACHE_HOME:-$HOME/.cache}/tui-menu/` (`history.tsv`, `sort-mode`,
  `show-missing`, `last-status`)

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
  Only `cmd` is required; missing fields get defaults.
- Entries are keyed by the full command string, which may contain arguments. The
  executable/package default is `${cmd%% *}`.
- `build_lines` emits `cmd<TAB>display<TAB>package<TAB>installed`; fzf uses
  `--accept-nth=1` and `{1}` for that command field. ANSI color is applied to the
  display field only.
- fzf bindings shell-call the script's internal subcommands: `--_list`, `--_preview`,
  `--_copy`, `--_launch`, `--_edit`, `--_toggle-sort`, `--_toggle-missing`,
  `--_header`, `--_new-window`. Any new internal command needs a matching case in the
  dispatcher at the bottom of the script.
- Interactive `Enter` behavior depends on the `loop` argument: default mode loops back
  to the menu after the app exits; `--once` closes after launching.
- Requires Bash 5+ (associative arrays, `mapfile`, `${var,,}`). Keep it Bash, not
  POSIX `sh`.
- `VERSION` is hardcoded near the top (`tui-menu:5`); bump it when releasing.
