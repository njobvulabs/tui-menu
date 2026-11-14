# tui-menu

An fzf-based TUI launcher for terminal applications. Pick an app, launch it, and
<img width="1366" height="768" alt="image" src="https://github.com/user-attachments/assets/3293bcbe-168c-4f89-983c-dcd7a1e95a42" /> return to the menu when it exits. Built for Arch Linux, with package status and
install hints from `pacman`/`yay`.

## Requirements

- Bash 5+
- `fzf` (recommended; a numbered fallback menu is used without it)
- Optional: `tmux` for launch-in-new-window, `wl-copy` for clipboard copy,
  `pacman` for version display
- Optional: `rsvg-convert` to install PNG icon sizes, `desktop-file-validate` for
  desktop-entry validation, and `update-desktop-database` / `gtk-update-icon-cache`
  for GUI caches

## Install

### User install (GNOME / XFCE app menu)

```sh
./gui-install.sh
```

This installs the app, icon, and desktop shortcut for the current user:

```text
~/.local/bin/tui-menu
~/.local/share/applications/tui-menu.desktop
~/.local/share/icons/hicolor/.../tui-menu.{svg,png}
```

Search for "TUI Menu" in your application menu. The shortcut opens the menu in a
terminal.

### System install (TTY)

```sh
sudo ./install.sh
```

This installs under `/usr/local` by default. To install under `/usr`:

```sh
sudo ./install.sh --prefix /usr
```

Use `--destdir DIR` to stage files for packaging, or `install.sh --user` for the
same user-level layout as `gui-install.sh`.

### Manual install

```sh
install -Dm755 tui-menu ~/.local/bin/tui-menu
install -Dm644 tui-menu.desktop ~/.local/share/applications/tui-menu.desktop
install -Dm644 tui-menu.svg ~/.local/share/icons/hicolor/scalable/apps/tui-menu.svg
```

## Usage

```sh
tui-menu                  # interactive menu; loops after launched apps exit
tui-menu --once           # close after launching an app
tui-menu --list           # list installed apps
tui-menu --list=all       # list installed and missing apps
tui-menu --check          # report installed/missing apps (exits 1 if any are missing)
tui-menu --check-config   # validate apps.tsv (exits 1 on warnings)
tui-menu --help
tui-menu --version
```

### File managers

Built-in file managers: yazi, nnn, Midnight Commander (`mc`), and Superfile (`spf`).
Opening an audio or video file hands off to `mpv` (via each manager's opener/play
configuration) so media plays from the TTY.

### Keys

| Key | Action |
| --- | --- |
| Enter | Launch the selected app |
| Esc / C-q | Quit |
| C-o | Launch in a new tmux window (inside tmux) |
| C-y | Copy the command to the clipboard |
| C-r | Cycle curated / most-used / recent ordering |
| C-/ | Toggle the preview pane |
| F1 | Show help |
| F2 | Show / hide missing apps |
| F5 | Refresh the app list |
| C-e | Edit the app list |

## Configuration

The app list is a TSV file at:

```text
${XDG_CONFIG_HOME:-$HOME/.config}/tui-menu/apps.tsv
```

Override the path with `TUI_MENU_CONFIG`. Interactive mode and `C-e` create the file
with commented examples if it does not exist.

Format:

```text
cmd<TAB>label<TAB>description<TAB>category<TAB>tags<TAB>package
```

Only `cmd` is required. For example:

```text
htop	htop	System monitor	Monitor	system,process	htop
```

- Reuse a built-in command name to override that entry.
- Prefix a command with `!` to hide a built-in (for example, `!nano`).
- Run `tui-menu --check-config` to check for duplicate commands, malformed fields, and
  hide directives that match nothing.
- Search matches labels, descriptions, categories, and tags.
- Set `NO_COLOR=1` or `TUI_MENU_COLOR=never` to disable color.

## State

History, sort mode, missing-app visibility, last launch status, and transient notices
are stored in:

```text
${XDG_CACHE_HOME:-$HOME/.cache}/tui-menu/
```
