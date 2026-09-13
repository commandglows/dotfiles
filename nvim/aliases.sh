# Neovim Configuration Switcher Aliases
# Source this file in your ~/.bashrc or ~/.zshrc
# Example: source $(dirname "${BASH_SOURCE[0]}")/aliases.sh

# Get the directory of this script dynamically
DOTFILES_NVIM_ALIASES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Main switcher alias
alias nvim-switch="$DOTFILES_NVIM_ALIASES_DIR/switch-config.sh"
alias nv-switch="$DOTFILES_NVIM_ALIASES_DIR/switch-config.sh"

# Quick access to different configs using NVIM_APPNAME
alias nv3="NVIM_APPNAME=nvim3 nvim"
alias nv6="NVIM_APPNAME=nvim6 nvim"
alias nv11="NVIM_APPNAME=nvim11 nvim"
alias nv22="NVIM_APPNAME=nvim22 nvim"

# Alternative names for those who prefer full names
alias nvim3="NVIM_APPNAME=nvim3 nvim"
alias nvim6="NVIM_APPNAME=nvim6 nvim"
alias nvim11="NVIM_APPNAME=nvim11 nvim"
alias nvim22="NVIM_APPNAME=nvim22 nvim"

# Useful shortcuts
alias nv-list="nvim-switch --list"
alias nv-current="nvim-switch --current"

# Silent load - no messages

# pnpm cache clearing alias
alias pnpm-clear="pnpm store prune"

# =============================================================================
# Git Auto-Fetch - Keeps remote status up-to-date for Starship prompt
# =============================================================================
# Fetches in background every 5 minutes when in a git repo
# This makes Starship's ahead/behind indicators accurate

GIT_AUTO_FETCH_INTERVAL=300  # 5 minutes in seconds

_git_auto_fetch() {
    # Only run if we're in a git repo
    local git_dir
    git_dir="$(git rev-parse --git-dir 2>/dev/null)" || return 0

    # Use absolute path for the lock file
    local repo_root
    repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || return 0
    local cache_file="${repo_root}/.git/.last_auto_fetch"

    # Check if enough time has passed since last fetch
    local now last_fetch
    now=$(date +%s)

    if [[ -f "$cache_file" ]]; then
        last_fetch=$(cat "$cache_file" 2>/dev/null || echo 0)
        if (( now - last_fetch < GIT_AUTO_FETCH_INTERVAL )); then
            return 0  # Too soon, skip fetch
        fi
    fi

    # Update timestamp immediately to prevent concurrent fetches
    echo "$now" > "$cache_file" 2>/dev/null

    # Fetch in background, completely silent
    (git fetch --all --quiet 2>/dev/null &)
}

# Hook into PROMPT_COMMAND to run before each prompt
if [[ -n "${BASH_VERSION:-}" ]]; then
    # Bash: append to PROMPT_COMMAND
    if [[ "${PROMPT_COMMAND:-}" != *"_git_auto_fetch"* ]]; then
        PROMPT_COMMAND="_git_auto_fetch${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
    fi
elif [[ -n "${ZSH_VERSION:-}" ]]; then
    # Zsh: use precmd hook
    autoload -Uz add-zsh-hook 2>/dev/null
    add-zsh-hook precmd _git_auto_fetch 2>/dev/null
fi
