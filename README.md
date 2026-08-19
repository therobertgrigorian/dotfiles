# dotfiles

Personal macOS (Apple Silicon) dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).
Terminal-centric, Vim keybindings everywhere, Catppuccin Mocha throughout.

Files at the repo root map one-to-one onto `$HOME`: `stow .` symlinks `.zshrc` to
`~/.zshrc`, `.config/nvim/` to `~/.config/nvim/`, and so on. Editing a file here
changes the live machine config immediately - there is no build or sync step.

## Install

On a fresh machine:

```sh
git clone git@github.com:therobertgrigorian/dotfiles.git ~/Workspace/dotfiles
cd ~/Workspace/dotfiles
./bootstrap.sh
```

`bootstrap.sh` is idempotent - safe to re-run. It installs Homebrew, everything in
the `Brewfile`, runs `stow`, sets up the plugin managers (TPM, Zinit, fzf,
devbox), installs global Node CLIs against `node@24`, switches the login shell to
Homebrew zsh, and applies a couple of macOS keyboard defaults.

To only relink the configs, without touching packages:

```sh
cd ~/Workspace/dotfiles
stow .      # link
stow -D .   # unlink
stow -R .   # relink
```

Always run stow from the repo root - the target directory comes from `.stowrc`.
`.stow-local-ignore` controls what stays repo-only (`.git`, `Brewfile`,
`bootstrap.sh`, `AGENTS.md`).

## What's in here

| Area | Tool | Config |
|------|------|--------|
| Terminal | Ghostty | `.config/ghostty/` |
| Shell | Zsh + Zinit + Starship | `.zshrc`, `.config/starship.toml` |
| Multiplexer | tmux + TPM, prefix `C-a` | `.config/tmux/` |
| Editor | Neovim + lazy.nvim, leader `Space` | `.config/nvim/` |
| Window manager | AeroSpace, i3-like, `alt+hjkl` | `.aerospace.toml` |
| Shell history | Atuin, synced, vim keymap | `.config/atuin/` |
| Files | Yazi | `.config/yazi/` |
| Fuzzy find | fzf + fd | `.fzf.sh` |
| Git | lazygit, gh, gh-dash | `.config/lazygit/`, `.config/gh/` |
| Packages | Homebrew | `Brewfile` - 53 formulae, 14 casks, 5 taps |

Neovim plugins live under `.config/nvim/lua/plugins/`, split by concern
(`coding/`, `editor/`, `helpers/`, `styling/`). Each file returns a lazy.nvim spec.

`.local/bin/mw` is a small work-specific extra: it reports the status of the
net2phone production change window, with a `--tmux` mode for the status bar.

## Conventions

- **Catppuccin Mocha everywhere.** Any new tool config should use the same palette:
  base `#1e1e2e`, text `#cdd6f4`, surface0 `#313244`.
- **Vim keys everywhere** - zsh, tmux, atuin, Neovim, AeroSpace.
- **Fira Code Nerd Font** in the terminal.
- **macOS only.** Paths assume Homebrew at `/opt/homebrew`.

`AGENTS.md` has the detailed version - directory layout, per-language style rules,
and the gotchas worth knowing before editing (there are a few).

## What is deliberately not here

Anything an application rewrites on its own, and anything carrying credentials or
account identity, is gitignored: agent state and session logs, Cursor chat
databases and CLI config, gcloud OAuth tokens, 1Password daemon config, Raycast
state, TPM-installed tmux plugins, yarn global `node_modules`.

Secrets are never stored in this repo. `.config/op/pi.env` holds only
1Password secret references (`op://vault/item/field`), resolved at runtime by
`op run`. Add a real key there and it lands in git - use a reference instead.
