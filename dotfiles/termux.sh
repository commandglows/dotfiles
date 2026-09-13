#!/usr/bin/env bash

# Script d'installation ALLÉGÉ pour Termux (Android)
# Version minimaliste pour édition Markdown: pas d'agents IA, pas de stack web.

## Configuration logging
LOG_FILE="${TERMUX_DOTFILES_LOG_FILE:-$HOME/termux-install.log}"
VERBOSE="${TERMUX_DOTFILES_VERBOSE:-0}"
export DEBIAN_FRONTEND=noninteractive
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    case "$level" in
        ERROR|WARN) echo "$message" ;;
        INFO) [ "$VERBOSE" = "1" ] && echo "$message" ;;
    esac
}

step() {
    log "INFO" "$1"
    echo "$1"
}

apt_termux() {
    apt-get \
        -o Dpkg::Options::=--force-confdef \
        -o Dpkg::Options::=--force-confold \
        "$@"
}

install_packages() {
    apt_termux install -y "$@" >/dev/null 2>&1
}

step "Installation Termux dotfiles..."

if ! command -v pkg >/dev/null 2>&1; then
    log "ERROR" "❌ This installer must run inside Termux (pkg command not found)"
    exit 1
fi

mkdir -p "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/tmp"

# --- 1. Packages Termux essentiels ---
step "1/6 Installation des paquets Termux..."
apt_termux update >/dev/null 2>&1
dpkg --force-confdef --force-confold --configure -a >/dev/null 2>&1 || true
install_packages \
  git \
  curl \
  wget \
  neovim \
  ripgrep \
  fd \
  fzf \
  openssh \
  autossh \
  mosh \
  tmux \
  lsof \
  netcat-openbsd \
  tar \
  unzip \
  ranger \
  tree \
  termux-api >/dev/null 2>&1

log "INFO" "✅ Termux packages installed"

# Vérifier Neovim
if command -v nvim &> /dev/null; then
    log "INFO" "✅ Neovim: $(nvim --version | head -n 1)"
else
    log "ERROR" "❌ Neovim installation failed"
    exit 1
fi

# --- 2. Nerd Fonts pour Termux ---
step "2/6 Configuration de la Nerd Font..."

# Termux utilise un système de fonts différent
FONT_DIR="$HOME/.termux"
mkdir -p "$FONT_DIR"

# Vérifier si unzip est installé
if ! command -v unzip &> /dev/null; then
    log "INFO" "Installing unzip..."
    install_packages unzip
fi

FONT_INSTALLED=false

if [ -f "$FONT_DIR/font.ttf" ] && [ ! -s "$FONT_DIR/font.ttf" ]; then
    log "WARN" "⚠️  Existing ~/.termux/font.ttf is empty, reinstalling Nerd Font"
    rm -f "$FONT_DIR/font.ttf"
fi

if [ ! -f "$FONT_DIR/font.ttf" ]; then
    log "INFO" "Downloading JetBrainsMono Nerd Font..."
    FONT_TMP_DIR="$(mktemp -d "$HOME/tmp/nerd-font.XXXXXX")"

    # Télécharger JetBrainsMono Nerd Font (version complète avec icônes)
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip"

    if curl -fsSL "$FONT_URL" -o "$FONT_TMP_DIR/JetBrainsMono.zip"; then
        log "INFO" "Download complete, extracting..."

        if unzip -q "$FONT_TMP_DIR/JetBrainsMono.zip" "JetBrainsMonoNerdFont-Regular.ttf" -d "$FONT_TMP_DIR" 2>/dev/null; then
            if [ -f "$FONT_TMP_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]; then
                if cp "$FONT_TMP_DIR/JetBrainsMonoNerdFont-Regular.ttf" "$FONT_DIR/font.ttf" && [ -s "$FONT_DIR/font.ttf" ]; then
                    chmod 644 "$FONT_DIR/font.ttf"
                    log "INFO" "✅ Nerd Font installed to ~/.termux/font.ttf"
                    FONT_INSTALLED=true
                else
                    rm -f "$FONT_DIR/font.ttf"
                    log "ERROR" "❌ Failed to install Nerd Font to ~/.termux/font.ttf"
                fi
            else
                log "WARN" "⚠️  Font file not found after extraction"
            fi
        else
            log "WARN" "⚠️  Failed to extract font from zip"
        fi
    else
        log "ERROR" "❌ Failed to download Nerd Font from GitHub"
        log "INFO" "💡 Alternative: Install 'Termux:Styling' app from F-Droid"
    fi

    rm -rf "$FONT_TMP_DIR"
else
    log "INFO" "✅ Nerd Font already configured in ~/.termux/font.ttf"
    FONT_INSTALLED=true
fi

# --- 3. Outils légers uniquement ---
step "3/6 Installation des outils légers..."

# Starship (prompt)
if ! command -v starship &> /dev/null; then
    log "INFO" "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y --bin-dir "$HOME/.local/bin" >/dev/null 2>&1
    if [ $? -eq 0 ] && [ -f "$HOME/.local/bin/starship" ]; then
        log "INFO" "✅ Starship installed to ~/.local/bin"
    else
        log "ERROR" "❌ Starship installation failed"
    fi
else
    log "INFO" "✅ Starship already installed"
fi

# Zoxide (smart cd) - available in Termux repos
if ! command -v zoxide &> /dev/null; then
    log "INFO" "Installing Zoxide..."
    install_packages zoxide
    if command -v zoxide &> /dev/null; then
        log "INFO" "✅ Zoxide installed via pkg"
    else
        log "ERROR" "❌ Zoxide installation failed"
    fi
else
    log "INFO" "✅ Zoxide already installed"
fi

# Termux theme picker
log "INFO" "🎨 Installing termux-theme..."
if curl -fsSL https://raw.githubusercontent.com/dianedef/termux-theme/main/install.sh -o "$HOME/tmp/termux-theme-install.sh"; then
    if sh "$HOME/tmp/termux-theme-install.sh" >/dev/null 2>&1 && command -v termux-theme &> /dev/null; then
        log "INFO" "✅ termux-theme installed"
    else
        log "WARN" "⚠️  termux-theme installation failed"
    fi
    rm -f "$HOME/tmp/termux-theme-install.sh"
else
    log "WARN" "⚠️  Could not download termux-theme installer"
fi

# File manager - Use Ranger (already installed via pkg)
if command -v ranger &> /dev/null; then
    log "INFO" "✅ Ranger file manager installed (use 'ranger' command)"
else
    log "WARN" "⚠️  Ranger not found, install with: pkg install ranger"
fi

# ShipGlows owns its runtime and tunnel commands. Dotfiles only reports whether
# the official installer has already provided them.
SHIPGLOWS_LOCAL_INSTALLED=false
step "4/6 Vérification des tunnels ShipGlows..."
if command -v urls >/dev/null 2>&1 && command -v tunnel >/dev/null 2>&1; then
    SHIPGLOWS_LOCAL_INSTALLED=true
    log "INFO" "✅ ShipGlows local tunnel tools available (urls/tunnel)"
else
    log "INFO" "ℹ️  Install ShipGlows separately with its official bootstrap to enable urls/tunnel"
fi

# --- 4. Configuration Neovim (MyNeovimTermux) ---
step "5/6 Configuration de Neovim..."

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_CONFIG_DIR="$HOME/.config/nvim"

# --- 5. Symlinks ---
log "INFO" "Creating symlinks..."

next_backup_path() {
    local TARGET=$1
    local BACKUP_PATH="${TARGET}.backup.$(date +%s)"
    local SUFFIX=1

    while [ -e "$BACKUP_PATH" ] || [ -L "$BACKUP_PATH" ]; do
        BACKUP_PATH="${TARGET}.backup.$(date +%s).$SUFFIX"
        SUFFIX=$((SUFFIX + 1))
    done

    echo "$BACKUP_PATH"
}

create_symlink() {
    local SOURCE=$1
    local TARGET=$2
    local SOURCE_REAL

    [ ! -e "$SOURCE" ] && { log "WARN" "⚠️  $SOURCE not found"; return; }
    SOURCE_REAL="$(readlink -f "$SOURCE" 2>/dev/null || echo "$SOURCE")"

    if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
        if [ -L "$TARGET" ]; then
            local TARGET_REAL
            TARGET_REAL="$(readlink -f "$TARGET" 2>/dev/null || true)"
            if [ "$TARGET_REAL" = "$SOURCE_REAL" ]; then
                log "INFO" "Already linked: $TARGET -> $SOURCE"
                return
            fi
            if ! rm -f "$TARGET"; then
                log "ERROR" "Failed to remove stale symlink: $TARGET"
                return 1
            fi
            log "INFO" "Removed stale symlink: $TARGET"
        else
            local BACKUP_PATH
            BACKUP_PATH="$(next_backup_path "$TARGET")"
            if ! mv "$TARGET" "$BACKUP_PATH"; then
                log "ERROR" "Failed to back up existing target: $TARGET -> $BACKUP_PATH"
                return 1
            fi
            log "WARN" "Existing target backed up: $TARGET -> $BACKUP_PATH"
        fi
    fi

    mkdir -p "$(dirname "$TARGET")"
    if ! ln -s "$SOURCE" "$TARGET"; then
        log "ERROR" "Failed to link: $TARGET -> $SOURCE"
        return 1
    fi
    log "INFO" "Linked: $TARGET -> $SOURCE"
}

# Neovim config - Use MyNeovimTermux, fallback to MyNeovim
if [ -d "$SOURCE_DIR/nvim/MyNeovimTermux" ]; then
    create_symlink "$SOURCE_DIR/nvim/MyNeovimTermux" "$NVIM_CONFIG_DIR"
elif [ -d "$SOURCE_DIR/nvim/MyNeovim" ]; then
    create_symlink "$SOURCE_DIR/nvim/MyNeovim" "$NVIM_CONFIG_DIR"
fi

# Remove leftovers from older LazyVim/Mason Termux runs without deleting the safe whitelist.
if [ -d "$HOME/.local/share/nvim/mason" ]; then
    rm -rf "$HOME/.local/share/nvim/mason"
    log "INFO" "Removed old Neovim Mason data"
fi

if [ -d "$HOME/.local/share/nvim/lazy" ]; then
    for plugin in \
        LazyVim \
        nvim-lspconfig \
        mason.nvim \
        mason-lspconfig.nvim \
        nvim-treesitter \
        conform.nvim \
        CopilotChat.nvim \
        copilot.lua \
        avante.nvim \
        codecompanion.nvim \
        claudecode.nvim \
        agentic.nvim \
        augment.vim \
        gemini-cli.nvim; do
        rm -rf "$HOME/.local/share/nvim/lazy/$plugin"
    done
    log "INFO" "Removed old heavy Neovim plugin data"
fi

# Termux properties
if [ -f "$SOURCE_DIR/termux/termux.properties" ]; then
    create_symlink "$SOURCE_DIR/termux/termux.properties" "$HOME/.termux/termux.properties"
    if command -v termux-reload-settings >/dev/null 2>&1; then
        termux-reload-settings >> "$LOG_FILE" 2>&1 || log "WARN" "⚠️  Could not reload Termux settings automatically"
    fi
fi

# Ranger (primary file manager for Termux)
[ -d "$SOURCE_DIR/ranger" ] && create_symlink "$SOURCE_DIR/ranger" "$HOME/.config/ranger"

# Starship (utilise la version simplifiée)
if [ -f "$SOURCE_DIR/starship/starship-simple.toml" ]; then
    create_symlink "$SOURCE_DIR/starship/starship-simple.toml" "$HOME/.config/starship.toml"
    log "INFO" "✅ Using simplified Starship config"
elif [ -f "$SOURCE_DIR/starship/starship.toml" ]; then
    create_symlink "$SOURCE_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
fi

# --- 6. Shell integration ---
step "6/6 Configuration du shell..."

# Make scripts executable
for script in "switch-config.sh" "nvim-multi" "aliases.sh" "shell-integration.sh"; do
    [ -f "$SOURCE_DIR/nvim/$script" ] && chmod +x "$SOURCE_DIR/nvim/$script"
done

# Ajouter à ~/.bashrc
BASHRC="$HOME/.bashrc"
touch "$BASHRC"
sed -i 's|$HOME/dotfiles/nvim/shell-integration\.sh|$HOME/.dotfiles/nvim/shell-integration.sh|g' "$BASHRC" 2>/dev/null || true

# Shell integration
if ! grep -q "shell-integration.sh" "$BASHRC" 2>/dev/null; then
    echo "" >> "$BASHRC"
    echo "# Neovim config switcher" >> "$BASHRC"
    echo '[ -f "$HOME/.dotfiles/nvim/shell-integration.sh" ] && source "$HOME/.dotfiles/nvim/shell-integration.sh"' >> "$BASHRC"
    log "INFO" "✅ Added shell integration"
fi

# Add cargo/local bin to PATH for Starship/Zoxide
if ! grep -q "\.cargo/bin" "$BASHRC"; then
    echo "" >> "$BASHRC"
    echo '# Cargo and local binaries' >> "$BASHRC"
    echo 'export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"' >> "$BASHRC"
    log "INFO" "✅ Added cargo/local bin to PATH"
fi

# autossh on Termux can need the OpenSSH binary path explicitly.
if ! grep -q "AUTOSSH_PATH" "$BASHRC"; then
    echo "" >> "$BASHRC"
    echo '# autossh on Termux' >> "$BASHRC"
    echo 'command -v ssh >/dev/null && export AUTOSSH_PATH="$(command -v ssh)"' >> "$BASHRC"
    log "INFO" "✅ Added autossh path to bashrc"
fi

# Starship (check PATH after adding it above)
if ! grep -q "starship init" "$BASHRC"; then
    echo "" >> "$BASHRC"
    echo '# Starship prompt' >> "$BASHRC"
    echo 'command -v starship >/dev/null && eval "$(starship init bash)"' >> "$BASHRC"
    log "INFO" "✅ Added Starship to bashrc"
fi

# Zoxide (check PATH after adding it above)
if ! grep -q "zoxide init" "$BASHRC"; then
    echo "" >> "$BASHRC"
    echo '# Zoxide' >> "$BASHRC"
    echo 'command -v zoxide >/dev/null && eval "$(zoxide init bash)"' >> "$BASHRC"
    log "INFO" "✅ Added Zoxide to bashrc"
fi

# Aliases essentiels - Toujours écraser pour avoir la dernière version
# Remove old aliases block (between markers)
sed -i '/# Termux aliases/,/# END Termux aliases/d' "$BASHRC" 2>/dev/null
cat >> "$BASHRC" << 'EOF'

# Termux aliases
alias i='bash ~/.dotfiles/dotfiles/termux.sh'
alias dot='~/.dotfiles/dotfiles/termux.sh'
alias dotfiles='~/.dotfiles/dotfiles/termux.sh'
alias cls='clear'

# Git shortcuts
alias gs='git status'
alias ga='git add .'
gc() { git commit -m "${1:-up}"; }
function gp { if [ -n "$(git status --porcelain)" ]; then git add -A && git commit -m "${1:-up}"; fi; git push; }
alias gl='git pull'

# Termux specific
alias termux-wake='termux-wake-lock'
alias termux-sleep='termux-wake-unlock'
alias storage='cd ~/storage/shared'
alias dl='cd ~/storage/downloads'

# File managers
alias n='nvim'
alias r='ranger'
alias thermux='termux-theme'

# END Termux aliases
EOF
log "INFO" "✅ Added/Updated Termux aliases"

# --- 7. Agents / web tooling intentionally skipped ---
log "INFO" "🤖 Skipping AI agents, MCP, and web tooling on Termux"
log "INFO" "✅ Termux profile kept focused on Markdown editing"

# --- Git Identity Configuration ---
log "INFO" "👤 Configuring Git identity..."
git config --global user.name "Diane"
git config --global user.email "deforesd@gmail.com"
log "INFO" "✅ Git identity configured"

# --- 8. Finalisation ---
echo ""
log "INFO" "Termux installation complete"

REPORT_RESET="\033[0m"
REPORT_BOLD="\033[1m"
REPORT_DIM="\033[2m"
REPORT_GREEN="\033[0;32m"
REPORT_CYAN="\033[0;36m"
REPORT_BLUE="\033[0;34m"
REPORT_YELLOW="\033[1;33m"
REPORT_MAGENTA="\033[0;35m"
REPORT_RED="\033[0;31m"

report() {
    printf "%b\n" "$1"
}

report "${REPORT_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${REPORT_RESET}"
report "${REPORT_BOLD}${REPORT_GREEN}✅ Installation Termux terminée${REPORT_RESET}"
report "${REPORT_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${REPORT_RESET}"
report ""
report "${REPORT_BOLD}${REPORT_YELLOW}🚀 Prochaine étape${REPORT_RESET}"
report "  ${REPORT_GREEN}source ~/.bashrc${REPORT_RESET}"
report "  ${REPORT_GREEN}re${REPORT_RESET}"
report ""
report "${REPORT_BOLD}${REPORT_MAGENTA}📦 Profil installé${REPORT_RESET}"
report "  ${REPORT_GREEN}✓${REPORT_RESET} 📝 Neovim Markdown avec config MyNeovimTermux"
report "  ${REPORT_GREEN}✓${REPORT_RESET} 🔌 Plugins légers: snacks, vim-pencil, surround, gitsigns, markdown"
report "  ${REPORT_GREEN}✓${REPORT_RESET} 📁 Navigation fichiers: ranger, ripgrep, fd, fzf"
report "  ${REPORT_GREEN}✓${REPORT_RESET} 🐚 Shell: Starship, Zoxide, aliases Termux"
report "  ${REPORT_GREEN}✓${REPORT_RESET} 🔐 Connexion: OpenSSH, autossh, Mosh, tmux"
report "  ${REPORT_GREEN}✓${REPORT_RESET} 🎨 Apparence: JetBrainsMono Nerd Font, termux-theme"
if [ "$SHIPGLOWS_LOCAL_INSTALLED" = true ]; then
    report "  ${REPORT_GREEN}✓${REPORT_RESET} 🚇 ShipGlows local tunnels: urls, tunnel"
fi
report ""
report "${REPORT_BOLD}${REPORT_BLUE}⌨️  Commandes utiles${REPORT_RESET}"
report "  ${REPORT_CYAN}n${REPORT_RESET}          Ouvrir Neovim"
report "  ${REPORT_CYAN}r${REPORT_RESET}          Ouvrir Ranger"
report "  ${REPORT_CYAN}thermux${REPORT_RESET}    Ouvrir le sélecteur de thème"
if [ "$SHIPGLOWS_LOCAL_INSTALLED" = true ]; then
    report "  ${REPORT_CYAN}urls${REPORT_RESET}       Ouvrir les tunnels ShipGlows"
    report "  ${REPORT_CYAN}tunnel${REPORT_RESET}     Gérer un tunnel ShipGlows"
fi
report "  ${REPORT_CYAN}re${REPORT_RESET}         Recharger le shell"
report ""
if [ "$FONT_INSTALLED" = true ] && [ -s "$HOME/.termux/font.ttf" ]; then
    report "${REPORT_BOLD}${REPORT_GREEN}✨ Icônes${REPORT_RESET}"
    report "  La Nerd Font est installée dans ${REPORT_CYAN}~/.termux/font.ttf${REPORT_RESET}."
    report "  Fermez complètement Termux puis rouvrez-le pour l'activer."
else
    report "${REPORT_BOLD}${REPORT_YELLOW}⚠️  Icônes${REPORT_RESET}"
    report "  La Nerd Font n'a pas été installée automatiquement."
    report "  Consultez le log ou utilisez Termux:Styling depuis F-Droid."
fi
report ""
report "${REPORT_BOLD}${REPORT_RED}🚫 Non installé volontairement${REPORT_RESET}"
report "  ${REPORT_DIM}• Node.js et stack web${REPORT_RESET}"
report "  ${REPORT_DIM}• MCP${REPORT_RESET}"
report "  ${REPORT_DIM}• Agents IA${REPORT_RESET}"
report "  ${REPORT_DIM}• Copilot, Claude, Codex, OpenCode, Aider${REPORT_RESET}"
report "  ${REPORT_DIM}• Mason, LSP lourds, Treesitter auto-installé${REPORT_RESET}"
report ""
report "${REPORT_BOLD}${REPORT_DIM}🧾 Détails techniques${REPORT_RESET}"
report "  Log: ${REPORT_CYAN}$LOG_FILE${REPORT_RESET}"
report "  Debug: ${REPORT_CYAN}TERMUX_DOTFILES_VERBOSE=1 bash ~/.dotfiles/dotfiles/termux.sh${REPORT_RESET}"
report "${REPORT_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${REPORT_RESET}"
