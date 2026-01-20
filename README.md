# dotfiles

Opinionated dotfiles for a macOS setup, organized for GNU Stow. The repo is split by app so you can stow only what you want.

## Structure

Each top-level directory is a stow package unless noted:

- `zsh` - shell config
- `git` - git config
- `vscode` - VS Code settings and extensions list
- `ghostty` - Ghostty terminal config
- `codex` - Codex CLI config
- `opencode` - OpenCode CLI config
- `chrome` - exported Chrome data (extensions + bookmarks)
- `scripts` - helper scripts (not a stow package)
- `images` - assets used by other configs (not a stow package)
- `Brewfile` - Homebrew bundle list (not a stow package)

## Requirements

- macOS
- GNU Stow (`brew install stow`)
- Homebrew (optional, for `Brewfile`)

## Install

These dotfiles are installed via the m-config installer script. Run it with curl:

```sh
curl -fsSL https://raw.githubusercontent.com/m-software-engineering/bash-scripts/refs/heads/main/m-config-install.sh | bash
```

That script clones the repo, installs dependencies, and stows packages into your home directory. To remove a package:

```sh
stow -D zsh
```

## Homebrew bundle (optional)

Install everything from the `Brewfile`:

```sh
brew bundle --file Brewfile
```

## Chrome exports

The `chrome` package stores exported data:

- `chrome/extensions-ids.txt` and `chrome/extensions-urls.txt` for extensions
- `chrome/bookmarks_1_19_26.html` for bookmarks

Export extensions from your local Chrome profiles:

```sh
scripts/scripts/chrome-export-extensions.sh
```

Open the Web Store pages for each exported extension:

```sh
scripts/scripts/chrome-install-extensions.sh
```

## VS Code

- Settings: `vscode/Library/Application Support/Code/User/settings.json`
- Extensions list: `vscode/vscode-extensions.txt`

Install listed extensions (requires `code` on PATH):

```sh
scripts/scripts/vscode-install-extensions.sh
```

## Maintenance scripts

- `scripts/scripts/macos-debloat.sh` provides an interactive, idempotent cleanup for macOS 26+.

## Notes

- This repo assumes a Stow-friendly layout; add new configs under a package directory that mirrors the target path.
- VS Code settings live under `vscode/Library/Application Support/Code/User/settings.json` to mirror macOS paths.

## Customize

Fork this repo and edit the package directories. Stow will keep your home directory clean while the repo stays versioned.
