# dotfiles

Opinionated dotfiles for a macOS setup, organized for GNU Stow. The repo is split by app so you can stow only what you want.

## Structure

Each top-level directory is a stow package unless noted:

- `zsh` - shell config
- `git` - git config
- `vscodium` - VSCodium settings and extensions list
- `nvim` - Neovim + LazyVim config
- `wezterm` - WezTerm terminal config
- `tmux` - tmux multiplexer config
- `homebrew` - Homebrew bundle, maintenance script, and LaunchAgent
- `ssh` - secure OpenSSH client defaults and host templates
- `codex` - Codex CLI config
- `opencode` - OpenCode config
- `scripts` - helper scripts
- `images` - assets used by other configs. `images/images/cloud.jpg` is the desktop wallpaper the installer can apply; stow links it to `~/images/cloud.jpg`
- `browser` - exported Chromium-family browser data (not a stow package)
- `test` - bats tests (not a stow package)
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

The bundle installs Concord (`brew "concord"`), the terminal Discord client, RTK (`brew "rtk"`), the CLI proxy that minimizes LLM token consumption, and Grok Bot (`cask "grok-bot"`). It does not install the Discord desktop cask. Concord session files under `~/.local/state/concord` stay on the machine and are not stowed. ai-memory is not a Homebrew formula; the installer downloads the native macOS release.

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

## Theme

Visual configs use [Catppuccin Latte](https://github.com/catppuccin/catppuccin), the light flavor:

- WezTerm color scheme and tab chrome
- tmux status, panes, and messages
- VSCodium `Catppuccin Latte` plus `Catppuccin.catppuccin-vsc`
- Neovim / LazyVim `catppuccin-latte` with Latte lualine, bufferline, and dashboard
- git-delta decorations, `light = true`, and `syntax-theme = ansi` so diffs follow the terminal
- zsh prompt, fzf, autosuggestions, and the `m config` banner
- Helium/Chrome theme id `jhjnalhegpceacdhbplhnakmkdliaddd`

Canonical tokens: background `#eff1f5`, foreground `#4c4f69`, mauve `#8839ef`,
green `#40a02b`, peach `#fe640b`, pink `#ea76cb`, blue `#1e66f5`, red `#d20f39`,
comment gray `#6c6f85`, surface `#ccd0da`.

Run the palette checks with `bats test/catppuccin-latte.bats`.

## WezTerm

The WezTerm profile balances a polished macOS appearance with sustained
efficiency on Apple silicon. It retains smooth 60 FPS rendering, animated UI,
cursor motion, and subtle translucency while using the low-power WebGPU
preference, limiting animation to 30 FPS, and avoiding the original heavy blur.
This keeps the Catppuccin Latte visual character without returning to the original
120 FPS compositor load.

## tmux

Stow the tmux package to install a lean XDG config:

```sh
stow --target "$HOME" tmux
```

Prefix is `Ctrl+Space`. Detach is `Ctrl+Space` then `d`. `Ctrl-d` stays EOF;
zsh `IGNORE_EOF` stops a stray `Ctrl-d` from killing the last pane. WezTerm
forwards `Ctrl+Space` to tmux. If the prefix does nothing, disable **Control+Space**
under System Settings → Keyboard → Keyboard Shortcuts → Input Sources.

Splits use the current pane path: `Ctrl+Space` `|` side-by-side, `Ctrl+Space` `-`
stacked. Move with `h`/`j`/`k`/`l`, resize with `H`/`J`/`K`/`L`, reload with `r`.

Run the config tests with `bats test/tmux-config.bats`.

## Neovim / LazyVim

Stow the nvim package to install a LazyVim starter with Catppuccin Latte:

```sh
stow --target "$HOME" nvim
```

`Brewfile` installs `neovim`, `ripgrep`, `fd`, `lazygit`, and
`font-fira-code-nerd-font`. First launch bootstraps lazy.nvim and LazyVim.

The config keeps LazyVim defaults for keymaps, LSP, and completion, then layers
Catppuccin Latte UI on lualine, bufferline, Snacks dashboard/indent, and Flash/WhichKey.
Language extras match this machine's stack: TypeScript, Python, Go, Docker,
JSON, YAML, TOML, Markdown, and Git.

Run the config tests with `bats test/nvim-config.bats`.

## macOS performance and appearance

Apply the conservative performance/appearance profile:

```sh
scripts/scripts/macos-performance-beauty.sh
```

Preview the settings without applying them:

```sh
scripts/scripts/macos-performance-beauty.sh --dry-run
```

The profile keeps macOS fast and polished by tuning global UI latency, Dock animation, Finder defaults, Stage Manager, screenshot behavior, and portable trackpad gestures including three-finger drag. It sets light appearance as the default by removing `AppleInterfaceStyle` and disabling automatic appearance switching. The accent stays system blue. It intentionally does not pin Dock apps, change hot corners, rewrite keyboard shortcuts, or alter power settings. Shottr and AltTab shortcuts live in a separate script.

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
- Theme: `Catppuccin Latte` via `Catppuccin.catppuccin-vsc`
- Extensions list: `vscodium/vscodium-extensions.txt`

Install listed extensions (requires `codium` on PATH):

```sh
scripts/scripts/vscodium-install-extensions.sh
```

The extension list defines required extensions rather than an exact profile. The installer skips extensions that are already installed, installs only missing entries, and leaves user-added extensions untouched. Repeated runs are safe and produce no extension changes once the required set is present.

Run the focused installer tests with `bats test/vscodium-install-extensions.bats`.

The shell and Git configs use `codium --wait` as the default local editor.

## AI agents

- Codex and OpenCode share the same global `AGENTS.md` guidance and use their native full-access/auto-approve settings. The shared Codex config stays portable: project trust, desktop appearance, plugins, and machine paths are local state and are not tracked.
- Both harnesses configure Chrome DevTools, Playwright, Context7, Figma, and DeepWiki MCP servers. Chrome DevTools and Playwright run through `npx`; the others use their official remote endpoints.
- Context7 reads `CONTEXT7_API_KEY` from the environment. The installer can write it to `~/.config/m-config/context7.env` with owner-only permissions; the key is never stored in this repository.
- Figma requires a one-time OAuth authorization in each harness: run `codex mcp login figma` and `opencode mcp auth figma` after installation.
- `Brewfile` installs `codex`, OpenCode V2 from `anomalyco/tap` (`opencode-v2`), RTK (`brew "rtk"`, https://github.com/rtk-ai/rtk), Grok Bot (`cask "grok-bot"`), Shottr (`cask "shottr"`), and AltTab (`cask "alt-tab"`). Do not add the core `opencode` formula: it is V1 and conflicts because both install an `opencode` binary. Do not install the crates.io `rtk` package; that name can resolve to a different project. Restart the shell after setup so the Context7 environment is loaded.
- The installer, not this bundle, installs the native ai-memory binary from https://github.com/akitaonrails/ai-memory and the Hermes skills `i-have-adhd` and `teach`.

## Maintenance scripts

- `homebrew/.config/homebrew/homebrew-maintenance.sh` updates and upgrades Homebrew packages for the LaunchAgent.
- `scripts/scripts/macos-debloat.sh` provides an interactive, idempotent cleanup for macOS 26+.
- `scripts/scripts/macos-performance-beauty.sh` applies the reusable macOS performance and appearance profile, including light appearance as the default.
- `scripts/scripts/configure-shottr-alttab.sh` sets Shottr area capture to Command-S and makes AltTab the Command-Tab switcher. Command-S is global, so it takes Save from other apps while Shottr is running. AltTab replaces the system switcher only after Accessibility permission and a relaunch.

## Notes

- This repo assumes a Stow-friendly layout; add new configs under a package directory that mirrors the target path.
- VSCodium settings live under `vscodium/Library/Application Support/VSCodium/User/settings.json` to mirror macOS paths.

## Customize

Fork this repo and edit the package directories. Stow will keep your home directory clean while the repo stays versioned.
