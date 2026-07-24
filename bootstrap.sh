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
# Non-fatal: a single failed formula/cask/extension must not abort the whole
# script (set -e), or later steps — crucially `stow` — would never run.
brew bundle --file="$DOTFILES/Brewfile" \
	|| warn "brew bundle reported failures — continuing (rerun 'brew bundle' later)"

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
# 8. Global Node CLIs — installed against the LTS node@24 (keg-only, so its
#    bin is not on PATH by default; reference it explicitly).
# ---------------------------------------------------------------------------
NODE_BIN="$(brew --prefix node@24 2>/dev/null)/bin"
if [ -x "$NODE_BIN/npm" ]; then
	log "installing global npm CLIs (pi coding agent, corepack)"
	PATH="$NODE_BIN:$PATH" npm install -g @earendil-works/pi-coding-agent \
		|| warn "pi-agent global install failed — continuing"
	PATH="$NODE_BIN:$PATH" corepack enable \
		|| warn "corepack enable failed — continuing"
else
	warn "node@24 not installed — skipping global npm CLIs"
fi

# ---------------------------------------------------------------------------
# 9. devbox — per-project toolchains via Nix. Global language runtimes come
#    from Homebrew (node@24, ruby, python@3.13, openjdk@21); devbox covers
#    anything a project needs pinned. Installer pulls in Nix (may need sudo).
# ---------------------------------------------------------------------------
if ! command -v devbox >/dev/null 2>&1; then
	log "installing devbox (pulls in Nix — may ask for sudo)"
	curl -fsSL https://get.jetify.com/devbox | bash -s -- -f \
		|| warn "devbox install failed — continuing"
else
	log "devbox already installed"
fi

# ---------------------------------------------------------------------------
# 10. Default shell — Homebrew zsh (newer than /bin/zsh)
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
# 11. Seed pi settings (COPY, not symlink: pi writes volatile state into it)
# ---------------------------------------------------------------------------
if [ ! -e "$HOME/.pi/agent/settings.json" ]; then
	cp "$DOTFILES/templates/pi-settings.json" "$HOME/.pi/agent/settings.json"
	log "seeded ~/.pi/agent/settings.json"
fi

# ---------------------------------------------------------------------------
# 12. Sanity checks for the pi -> 1Password integration.
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
