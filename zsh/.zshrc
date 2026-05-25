# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="crcandy"

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
zstyle ':omz:update' frequency 7

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="%Y-%m-%d %H:%M:%S"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git fzf zsh-interactive-cd colored-man-pages command-not-found zsh-completions zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='codium --wait'
fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Sourcing ENV configuration into the shell session
if [[ -f "$HOME/.local/bin/env" ]]; then
  . "$HOME/.local/bin/env"
fi

# Activating MISE at the start of the zsh session
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# --- ASCII banner (only in interactive shells) ---
if [[ -o interactive ]]; then
  # ASCII Art Banner for M Config (red)
  printf '\033[0;31m'

  cat << "EOF"
 Yb  dP .d88b. 8    8       db    888b. 8888    8    8 .d88b. 888 8b  8 .d88b  
  YbdP  8P  Y8 8    8      dPYb   8  .8 8www    8    8 YPwww.  8  8Ybm8 8P www 
   YP   8b  d8 8b..d8     dPwwYb  8wwK' 8       8b..d8     d8  8  8  "8 8b  d8 
   88   `Y88P' `Y88P'    dP    Yb 8  Yb 8888    `Y88P' `Y88P' 888 8   8 `Y88P' 
                                                                               
        ███▄ ▄███▓    ▄████▄    ▒█████    ███▄    █    █████▒ ██▓   ▄████ 
       ▓██▒▀█▀ ██▒   ▒██▀ ▀█   ▒██▒  ██▒  ██ ▀█   █  ▓██   ▒ ▓██▒  ██▒ ▀█▒
       ▓██    ▓██░   ▒▓█    ▄  ▒██░  ██▒▓ ██  ▀█ ██▒ ▒████ ░ ▒██▒▒ ██░▄▄▄░
       ▒██    ▒██    ▒▓▓▄ ▄██ ▒▒██   ██░▓ ██▒  ▐▌██▒ ░▓█▒  ░ ░██░░ ▓█  ██▓
       ▒██▒   ░██▒   ▒ ▓███▀  ░░ ████▓▒░▒ ██░   ▓██░ ░▒█░    ░██░░ ▒▓███▀▒
       ░ ▒░   ░  ░   ░ ░▒ ▒   ░░ ▒░▒░▒░ ░  ▒░   ▒ ▒   ▒ ░    ░▓    ░▒   ▒ 
       ░  ░      ░     ░  ▒      ░ ▒ ▒░ ░  ░░   ░ ▒░  ░       ▒ ░   ░   ░ 
       ░      ░      ░         ░ ░ ░ ▒      ░   ░ ░   ░ ░     ▒ ░░  ░   ░ 
              ░      ░ ░           ░ ░           ░           ░         ░ 
                     ░                                                               
EOF

  # Reset color
  printf '\033[0m'
fi
