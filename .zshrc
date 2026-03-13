setopt prompt_subst
autoload bashcompinit && bashcompinit
autoload -Uz compinit
compinit
complete -C '/usr/local/bin/aws_completer' aws

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

bindkey '^w' autosuggest-execute
bindkey '^e' autosuggest-accept
bindkey '^u' autosuggest-toggle
bindkey '^L' vi-forward-word
bindkey '^k' up-line-or-search
bindkey '^j' down-line-or-search

eval "$(starship init zsh)"
export STARSHIP_CONFIG=~/.config/starship.toml

export LANG=en_US.UTF-8

export EDITOR=/opt/homebrew/bin/nvim

alias edit=$EDITOR

alias la=tree
alias cat=bat

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."

bindkey jj vi-cmd-mode

# Tools
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow'
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Atuin - shell history (install via: brew install atuin)
if command -v atuin &>/dev/null; then
  eval "$(atuin init zsh)"
elif [[ -f "$HOME/.atuin/bin/env" ]]; then
  . "$HOME/.atuin/bin/env"
  eval "$(atuin init zsh)"
fi

export VOLTA_HOME="$HOME/.volta"

export XDG_CONFIG_HOME="/Users/robertgrigorian/.config"

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

[ -s "/Users/robertgrigorian/.bun/_bun" ] && source "/Users/robertgrigorian/.bun/_bun"

export BUN_INSTALL="$HOME/.bun"

export ANDROID_HOME=$HOME/Library/Android/sdk

# PATH setup
export PATH=/opt/homebrew/bin:$PATH
export PATH="$PATH:/opt/homebrew/opt/openjdk@17/bin"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$BUN_INSTALL/bin"
export PATH="$PATH:$VOLTA_HOME/bin"
export PATH="$PATH:$HOME/.rvm/bin"
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH="$PATH:$HOME/.antigravity/antigravity/bin"

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

zinit light Aloxaf/fzf-tab

