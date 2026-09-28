# dotfiles

macOS environment config for GNU Stow. Each top-level directory is a package that mirrors a path under `$HOME`, except `browser` and `test`.

The installer in [bash-scripts](https://github.com/m-software-engineering/bash-scripts) is the way to apply this repo. It clones, installs the Brewfile, stows packages, and prompts before appearance, wallpaper, and shortcuts.

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/m-software-engineering/bash-scripts/refs/heads/main/m-config-install.sh)"
```

## Update an existing clone

`pull.rebase` is true, so `git pull` refuses a dirty tree. Fast-forward, then restow and refresh Homebrew:

```sh
git -C "$HOME/dotfiles" fetch origin
git -C "$HOME/dotfiles" merge --ff-only origin/main
cd "$HOME/dotfiles"
stow --target "$HOME" --ignore='\.DS_Store$' \
  zsh git nvim wezterm tmux homebrew ssh codex opencode scripts images vscodium
brew bundle --file homebrew/.config/homebrew/Brewfile
```

Skip `browser` and `test`. They are data and checks, not home-directory packages. The top-level `Brewfile` is a symlink to `homebrew/.config/homebrew/Brewfile`.

## Change one package

Edit the package, preview, then stow:

```sh
stow -n -v --target "$HOME" --ignore='\.DS_Store$' nvim
stow --target "$HOME" --ignore='\.DS_Store$' nvim
```

Remove it:

```sh
stow -D --target "$HOME" nvim
```

Packages: `zsh`, `git`, `nvim`, `wezterm`, `tmux`, `homebrew`, `ssh`, `codex`, `opencode`, `scripts`, `images`, `vscodium`.

## Commands you actually run

```sh
scripts/scripts/macos-performance-beauty.sh --dry-run
scripts/scripts/macos-performance-beauty.sh
scripts/scripts/configure-shottr-alttab.sh --dry-run
scripts/scripts/configure-shottr-alttab.sh
scripts/scripts/macos-set-default-apps.sh --dry-run
scripts/scripts/vscodium-install-extensions.sh
scripts/scripts/macos-debloat.sh
homebrew/.config/homebrew/homebrew-maintenance.sh --dry-run --brewfile homebrew/.config/homebrew/Brewfile
```

`macos-debloat.sh` is interactive. Do not pipe answers into it.

Wallpaper file: `images/images/cloud.jpg`. Stow links it to `$HOME/images/cloud.jpg`. The installer sets it; do not point the desktop at a copy outside the clone.

Theme is Catppuccin Latte. The appearance script sets light mode by deleting `AppleInterfaceStyle`, not by writing `Light`.

tmux prefix is `Ctrl+Space`. If it does nothing, turn off Control+Space under System Settings → Keyboard → Keyboard Shortcuts → Input Sources.

## Constraints that break a clean install

- OpenCode is `opencode-v2` from `anomalyco/tap`. Do not add core `brew "opencode"`; both install an `opencode` binary.
- The Discord client is `concord`, not the Discord desktop cask.
- Do not re-add `claude`, `claude-code`, `discord`, `whatsapp`, or `steam`.
- Do not commit Context7 keys, Codex project trust, or machine paths. The key lives in `$HOME/.config/m-config/context7.env`.

SSH defaults refuse agent and password auth until a host file opts in. After `stow ssh`, copy `$HOME/.ssh/config.d/example.conf` and point it at one key.

## Check

```sh
bats test
shellcheck scripts/scripts/*.sh test/*.bats
```
