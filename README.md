# dotfiles

Opinionated dotfiles for a macOS setup, organized for GNU Stow. The repo is split by app so you can stow only what you want.

## Structure

Each top-level directory is a stow package:

- `zsh` - shell config
- `git` - git config
- `vscode` - VS Code settings
- `ghostty` - Ghostty terminal config
- `codex` - Codex CLI config
- `Brewfile` - Homebrew bundle list

## Requirements

- macOS
- GNU Stow (`brew install stow`)
- Homebrew (optional, for `Brewfile`)

## Install

Clone the repo and stow packages from the repo root:

```sh
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles

# pick what you want
stow zsh git vscode ghostty codex
```

That will symlink each package into your home directory. To remove a package:

```sh
stow -D zsh
```

## Homebrew bundle (optional)

Install everything from the `Brewfile`:

```sh
brew bundle --file Brewfile
```

## Notes

- This repo assumes a Stow-friendly layout; add new configs under a package directory that mirrors the target path.
- VS Code settings live under `vscode/Library/Application Support/Code/User/settings.json` to mirror macOS paths.

## Customize

Fork this repo and edit the package directories. Stow will keep your home directory clean while the repo stays versioned.
