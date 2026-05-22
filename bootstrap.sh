#!/usr/bin/env bash
# Bootstrap ~/.dotfiles on a fresh macOS (Apple Silicon) laptop.
# Idempotent — safe to re-run.

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
cd "$DOTFILES"

log()  { printf '\033[1;34m[bootstrap]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[bootstrap]\033[0m %s\n' "$*" >&2; }

# ---------------------------------------------------------------------------
# 1. Homebrew
# ---------------------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
	log "installing Homebrew"
	/bin/bash -c \
		"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Ensure brew is on PATH for the rest of the script (fresh installs).
if [ -x /opt/homebrew/bin/brew ]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ---------------------------------------------------------------------------
# 2. Brewfile — formulae, casks, taps, App Store apps
# ---------------------------------------------------------------------------
log "brew bundle (Brewfile)"
brew bundle --file="$DOTFILES/Brewfile"

# ---------------------------------------------------------------------------
# 3. Pre-create dirs stow must NOT fold into a single symlink.
#    If ~/.pi did not exist, `stow .` would symlink ~/.pi -> repo/.pi
#    and pi would write auth.json + sessions/ inside the repo.
# ---------------------------------------------------------------------------
mkdir -p "$HOME/.pi/agent"

# ---------------------------------------------------------------------------
# 4. Stow — symlink dotfiles into $HOME
# ---------------------------------------------------------------------------
if ! command -v stow >/dev/null 2>&1; then
	echo "error: GNU stow not installed (should be in Brewfile)" >&2
	exit 1
fi
log "stow ."
stow .

# ---------------------------------------------------------------------------
# 5. TPM — tmux plugin manager
#    Plugins themselves are installed inside tmux with: prefix + I
# ---------------------------------------------------------------------------
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
	log "installing TPM"
	git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
	log "TPM already installed"
fi

# ---------------------------------------------------------------------------
# 6. fzf — shell key bindings + completion (writes ~/.fzf.zsh)
# ---------------------------------------------------------------------------
if [ ! -f "$HOME/.fzf.zsh" ] && command -v fzf >/dev/null 2>&1; then
	log "installing fzf shell integration"
	"$(brew --prefix fzf)/install" --key-bindings --completion --no-update-rc
fi

# ---------------------------------------------------------------------------
# 7. Zinit — zsh plugin manager.
#    .zshrc also self-bootstraps this; we do it eagerly so the first
#    interactive shell starts up clean.
# ---------------------------------------------------------------------------
ZINIT_DIR="$HOME/.local/share/zinit/zinit.git"
if [ ! -d "$ZINIT_DIR" ]; then
	log "installing zinit"
	mkdir -p "$(dirname "$ZINIT_DIR")"
	chmod g-rwX "$HOME/.local/share/zinit"
	git clone --depth=1 https://github.com/zdharma-continuum/zinit "$ZINIT_DIR"
fi

# ---------------------------------------------------------------------------
# Helpers: some installers append to ~/.zshrc. After stow, that file is a
# symlink into the repo — we don't want third-party installers mutating
# tracked dotfiles. Snapshot before, restore after.
# ---------------------------------------------------------------------------
_zshrc_snapshot=""
preserve_zshrc() {
	_zshrc_snapshot=$(mktemp)
	cp -L "$HOME/.zshrc" "$_zshrc_snapshot"
}
restore_zshrc() {
	[ -n "$_zshrc_snapshot" ] || return 0
	cp "$_zshrc_snapshot" "$DOTFILES/.zshrc"
	rm -f "$_zshrc_snapshot"
	_zshrc_snapshot=""
}

# ---------------------------------------------------------------------------
# 8. Volta — Node toolchain manager (--skip-setup keeps it out of rc files)
# ---------------------------------------------------------------------------
if ! command -v volta >/dev/null 2>&1 && [ ! -x "$HOME/.volta/bin/volta" ]; then
	log "installing Volta"
	curl -fsSL https://get.volta.sh | bash -s -- --skip-setup
else
	log "Volta already installed"
fi

# ---------------------------------------------------------------------------
# 9. Bun — JS runtime. Installer writes to ~/.zshrc; preserve/restore.
# ---------------------------------------------------------------------------
if [ ! -x "$HOME/.bun/bin/bun" ]; then
	log "installing Bun"
	preserve_zshrc
	curl -fsSL https://bun.sh/install | bash || { restore_zshrc; exit 1; }
	restore_zshrc
else
	log "Bun already installed"
fi

# ---------------------------------------------------------------------------
# 10. RVM — Ruby version manager (--ignore-dotfiles keeps it out of rc files)
# ---------------------------------------------------------------------------
if [ ! -d "$HOME/.rvm" ]; then
	log "installing RVM"
	curl -sSL https://get.rvm.io | bash -s stable --ignore-dotfiles
else
	log "RVM already installed"
fi

# ---------------------------------------------------------------------------
# 11. Default shell — Homebrew zsh (newer than /bin/zsh)
# ---------------------------------------------------------------------------
BREW_ZSH="$(brew --prefix)/bin/zsh"
if [ -x "$BREW_ZSH" ] && [ "${SHELL:-}" != "$BREW_ZSH" ]; then
	if ! grep -qx "$BREW_ZSH" /etc/shells; then
		log "adding $BREW_ZSH to /etc/shells (sudo)"
		echo "$BREW_ZSH" | sudo tee -a /etc/shells >/dev/null
	fi
	log "chsh -s $BREW_ZSH"
	chsh -s "$BREW_ZSH" || warn "chsh failed — change login shell manually"
fi

# ---------------------------------------------------------------------------
# 12. Seed pi settings (COPY, not symlink: pi writes volatile state into it)
# ---------------------------------------------------------------------------
if [ ! -e "$HOME/.pi/agent/settings.json" ]; then
	cp "$DOTFILES/templates/pi-settings.json" "$HOME/.pi/agent/settings.json"
	log "seeded ~/.pi/agent/settings.json"
fi

# ---------------------------------------------------------------------------
# 13. Sanity checks for the pi -> 1Password integration.
# ---------------------------------------------------------------------------
if ! command -v op >/dev/null 2>&1; then
	warn "1Password CLI 'op' not installed (brew install --cask 1password-cli)"
fi
if [ -f "$HOME/.config/op/pi.env" ]; then
	if ! grep -qE '^[A-Z_]+=op://' "$HOME/.config/op/pi.env" 2>/dev/null; then
		warn "~/.config/op/pi.env has no active entries — uncomment the providers you use"
	fi
fi

log "done"
log "next steps:"
log "  - launch tmux and press 'prefix + I' to install TPM plugins"
log "  - open nvim once to let lazy.nvim sync plugins"
log "  - restart your terminal to pick up the new login shell"
