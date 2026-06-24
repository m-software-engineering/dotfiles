# dotfiles

Opinionated dotfiles for a macOS setup, organized for GNU Stow. The repo is split by app so you can stow only what you want.

## Structure

Each top-level directory is a stow package unless noted:

- `zsh` - shell config
- `git` - git config
- `vscodium` - VSCodium settings and extensions list
- `wezterm` - WezTerm terminal config
- `homebrew` - Homebrew bundle, maintenance script, and LaunchAgent
- `ssh` - secure OpenSSH client defaults and host templates
- `codex` - Codex CLI config
- `claude` - Claude Code config
- `scripts` - helper scripts
- `images` - assets used by other configs
- `browser` - exported Chromium-family browser data (not a stow package)
- `Brewfile` - shortcut symlink to `homebrew/.config/homebrew/Brewfile`

## Requirements

- macOS
- Xcode Command Line Tools
- GNU Stow (`brew install stow`)
- Homebrew (optional, for `Brewfile`)

## Install

These dotfiles are installed via the m-config installer script. Run it with:

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/m-software-engineering/bash-scripts/refs/heads/main/m-config-install.sh)"
```

That script validates Command Line Tools, installs dependencies, and stows packages into your home directory.

If you already have a local dotfiles clone:

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/m-software-engineering/bash-scripts/refs/heads/main/m-config-install.sh)" -- --dotfiles-dir [YOUR-DOTFILES-DIR-PATH]
```

You can also use environment variables:

```sh
DOTFILES_DIR=[YOUR-DOTFILES-DIR-PATH] DOTFILES_REPO_URL=https://github.com/m-software-engineering/dotfiles.git bash -c "$(curl -fsSL https://raw.githubusercontent.com/m-software-engineering/bash-scripts/refs/heads/main/m-config-install.sh)"
```

To remove a package:

```sh
stow -D zsh
```

## Homebrew

The canonical bundle lives at `homebrew/.config/homebrew/Brewfile`. The top-level
`Brewfile` is a shortcut symlink for the existing bundle workflow.

Install everything from the bundle:

```sh
brew bundle --file Brewfile
```

Enable the daily Homebrew maintenance job after stowing `homebrew`:

```sh
stow --target "$HOME" homebrew
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.m-software-engineering.homebrew-maintenance.plist"
launchctl enable "gui/$(id -u)/com.m-software-engineering.homebrew-maintenance"
```

The LaunchAgent executes `$HOME/.config/homebrew/homebrew-maintenance.sh`, which is
installed by the `homebrew` package.

The job runs at 03:30 local time and performs `brew update`, `brew bundle install
--upgrade`, formula upgrades, greedy cask upgrades, and `brew cleanup --prune=14`.
Preview the command sequence without changing installed packages:

```sh
homebrew/.config/homebrew/homebrew-maintenance.sh --dry-run --brewfile homebrew/.config/homebrew/Brewfile
```

Logs are written to `~/Library/Logs/m-software-engineering/homebrew-maintenance.log`.
Launchd startup errors are mirrored to `/tmp/com.m-software-engineering.homebrew-maintenance.err.log`.

Disable the scheduled job:

```sh
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.m-software-engineering.homebrew-maintenance.plist"
```

## SSH

Stow the SSH package to install secure OpenSSH client defaults:

```sh
stow --target "$HOME" ssh
```

The global config disables public-key, password, keyboard-interactive, and agent
forwarding auth by default. This prevents unknown servers from enumerating keys
loaded in `ssh-agent` or present in default identity paths. Add a local
host-specific file under `~/.ssh/config.d/` when a server should see exactly one
public key. Host snippets in that directory are ignored by Git except for the
tracked `example.conf` template.

Example host onboarding:

```sh
ssh-keygen -t ed25519 -a 100 -f "$HOME/.ssh/id_ed25519_github" -C "github"
cp "$HOME/.ssh/config.d/example.conf" "$HOME/.ssh/config.d/github.conf"
chmod 700 "$HOME/.ssh"
chmod 600 "$HOME/.ssh/config" "$HOME/.ssh/config.d/github.conf" "$HOME/.ssh/id_ed25519_github"
```

Then edit `~/.ssh/config.d/github.conf` so the `github.com` block is uncommented
and points at `~/.ssh/id_ed25519_github`. Confirm the effective config before
connecting:

```sh
ssh -G github.com | rg '^(pubkeyauthentication|identityfile|identitiesonly|passwordauthentication|kbdinteractiveauthentication) '
```

## macOS app defaults

Set Helium as the default browser, Microsoft Edge as the default PDF reader, and WezTerm as the default terminal handler:

```sh
scripts/scripts/macos-set-default-apps.sh
```

Preview the changes without applying them:

```sh
scripts/scripts/macos-set-default-apps.sh --dry-run
```

This script requires `duti`, which is installed by the `Brewfile`.

## macOS performance and appearance

Apply the conservative performance/appearance profile:

```sh
scripts/scripts/macos-performance-beauty.sh
```

Preview the settings without applying them:

```sh
scripts/scripts/macos-performance-beauty.sh --dry-run
```

The profile keeps macOS fast and polished by tuning global UI latency, Dock animation, Finder defaults, Stage Manager, screenshot behavior, and portable trackpad gestures including three-finger drag. It intentionally does not pin Dock apps, change hot corners, rewrite keyboard shortcuts, or alter power settings.

The m-config installer offers this step as an opt-in prompt.

## Browser exports

The `browser` directory stores exported Chromium-family browser data:

- `browser/extensions-ids.txt` and `browser/extensions-urls.txt` for extensions
- `browser/bookmarks_1_19_26.html` for bookmarks

Export extensions from your local Helium profiles:

```sh
scripts/scripts/browser-export-extensions.sh
```

Open the Web Store pages for each exported extension:

```sh
scripts/scripts/browser-install-extensions.sh
```

Set `BROWSER_PROFILE_ROOT` to export from another Chromium-family browser profile root.

## VSCodium

- Settings: `vscodium/Library/Application Support/VSCodium/User/settings.json`
- Extensions list: `vscodium/vscodium-extensions.txt`

Install listed extensions (requires `codium` on PATH):

```sh
scripts/scripts/vscodium-install-extensions.sh
```

The shell and Git configs use `codium --wait` as the default local editor.

## AI agents

- Codex is configured as a lean global default: full-access local sessions, approvals disabled, live web search enabled, and editor file opening disabled.
- Codex does not pin models, local providers, profiles, or global MCP servers; use CLI flags or project-level config when a repo needs those.
- Claude Code uses `permissions.defaultMode` set to `auto`.
- Claude Code loads the shared agent guidance from `~/.codex/AGENTS.md` through `claude/.claude/CLAUDE.md`; stow both `codex` and `claude` packages together.
- `Brewfile` installs `codex`, `claude`, and `claude-code`. If `claude` is not on PATH after setup, rerun `brew bundle` and restart the shell.

## Maintenance scripts

- `homebrew/.config/homebrew/homebrew-maintenance.sh` updates and upgrades Homebrew packages for the LaunchAgent.
- `scripts/scripts/macos-debloat.sh` provides an interactive, idempotent cleanup for macOS 26+.
- `scripts/scripts/macos-performance-beauty.sh` applies the reusable macOS performance and appearance profile.

## Notes

- This repo assumes a Stow-friendly layout; add new configs under a package directory that mirrors the target path.
- VSCodium settings live under `vscodium/Library/Application Support/VSCodium/User/settings.json` to mirror macOS paths.

## Customize

Fork this repo and edit the package directories. Stow will keep your home directory clean while the repo stays versioned.
