# AGENTS.md - Dotfiles Repository Guide

## Repository Overview

Personal dotfiles for macOS (Apple Silicon) managed with **GNU Stow**. All configs
live at `~/.dotfiles` and are symlinked into `$HOME` via `stow .`. There is no
Makefile, install script, or CI pipeline.

## Deployment

```bash
# From the repo root, symlink everything into $HOME:
stow .

# To unlink:
stow -D .

# To re-stow (unlink then relink):
stow -R .
```

`.stow-local-ignore` files at root and `.config/` control what gets excluded
(`.git`, `.volta`, runtime caches, node_modules, etc.).


## Directory Structure

```
.dotfiles/
  .aerospace.toml          # AeroSpace tiling window manager
  .config/
    atuin/config.toml       # Shell history (Atuin)
    bat/                    # bat (cat replacement) config + themes
    fish/                   # Minimal Fish shell support
    ghostty/config          # Ghostty terminal emulator
    gh/                     # GitHub CLI config
    git/ignore              # Global gitignore
    htop/htoprc             # htop process monitor
    nvim/                   # Neovim configuration (Lua)
    raycast/                # Raycast launcher extensions
    starship.toml           # Starship prompt
    tmux/tmux.conf          # Tmux + plugins (TPM)
    yazi/                   # Yazi TUI file manager + theme
    yarn/global/            # Global Yarn packages
  .fzf.sh                   # FZF shell integration
  .zprofile                 # Homebrew shellenv init
  .zshrc                    # Main Zsh configuration
```

## Neovim Configuration

**Plugin manager:** lazy.nvim  
**Leader key:** Space  
**Config entry:** `.config/nvim/init.lua` loads `plugins`, `keymaps`, `options`

### Plugin directory layout

Plugins are organized by concern under `.config/nvim/lua/plugins/`:

| Directory   | Purpose                                   |
|-------------|-------------------------------------------|
| `coding/`   | Dev tools (mason, yanky)                  |
| `editor/`   | Core editor (telescope, neo-tree, etc.)   |
| `helpers/`  | Utility plugins (which-key)               |
| `styling/`  | Appearance (colorscheme, bufferline, etc.)|

Each plugin file returns a lazy.nvim spec table (or array of tables).

### Adding a new plugin

Create a `.lua` file in the appropriate subdirectory. Name it after the plugin.
Return a lazy.nvim spec:

```lua
return {
  "author/plugin-name",
  event = "VeryLazy",
  config = function()
    require("plugin-name").setup({})
  end,
}
```

## Code Style Guidelines

### Lua (Neovim config)

- **Indentation:** 2 spaces, no tabs (`expandtab`, `tabstop=2`, `shiftwidth=2`)
- **Strings:** Double quotes for all string literals
- **Module pattern:** Every plugin file returns a table; no side effects at module level
- **Keymaps:** Prefer `vim.keymap.set()` over `vim.api.nvim_set_keymap()`
- **Options:** Prefer `vim.opt.X = value` over `vim.cmd("set X")`
- **File naming:** Lowercase, named after the plugin (e.g., `neo-tree.lua`)
- **No trailing whitespace or excessive blank lines**

### Shell (Zsh)

- **Quoting:** Quote paths with spaces; simple variable expansions may omit quotes
- **Aliases:** Short and terse (e.g., `la=tree`, `cat=bat`)
- **Functions:** Use `function name() { }` syntax
- **PATH:** Accumulated via repeated `export PATH="$PATH:..."` statements
- **Comments:** `#` with a space, use section headers for grouping
- **Indentation:** Tabs in functions (matches existing style)

### TOML / Config files

- **Color values:** Lowercase hex with `#` prefix (e.g., `#1e1e2e`)
- **Strings:** Double quotes for values

### General conventions

- **Theme:** Catppuccin Mocha everywhere (terminal, editor, tmux, bat, yazi, starship)
- **Keybindings:** Vim-centric in all tools (zsh, tmux, atuin, neovim)
- **Font:** Fira Code (Nerd Font variant) in terminal
- **No linters or formatters** are configured for the dotfiles themselves

## Key Toolchain

| Tool       | Manager/Config                          |
|------------|-----------------------------------------|
| Neovim     | lazy.nvim plugins, Lua config           |
| Tmux       | TPM plugin manager                      |
| Zsh        | Zinit plugin manager, Starship prompt   |
| Shell hist | Atuin (synced, vim keymap)              |
| Fuzzy find | FZF + fd                                |
| Files      | Yazi TUI file manager                   |
| Window mgr | AeroSpace (i3-like, alt+hjkl)          |
| Terminal   | Ghostty                                 |
| Node.js    | Volta (version manager)                 |
| JS runtime | Bun                                     |
| Ruby       | RVM                                     |
| Git        | gh CLI (HTTPS, nvim editor)             |

## Important Notes for Agents

1. **This is a stow-managed repo.** Files at the repo root map directly to `$HOME`.
   Do not restructure directories without understanding stow's symlink behavior.

2. **nvim-cmp completion framework is configured** with LSP, Codeium, snippet,
   buffer, and path sources. Mason auto-installs: ts_ls, lua_ls, html, cssls,
   jsonls. LSP uses Neovim 0.11+ `vim.lsp.config`/`vim.lsp.enable` API.

3. **Catppuccin Mocha consistency.** Any new tool config should use the Catppuccin
   Mocha color palette. Key colors: base `#1e1e2e`, text `#cdd6f4`, surface0
   `#313244`, green `#a6e3a1`, peach `#fab387`, blue `#89b4fa`.

4. **macOS only.** All paths assume macOS with Homebrew at `/opt/homebrew`. Do not
   add Linux-specific paths or package manager commands.

5. **XDG_CONFIG_HOME** is set to `$HOME/.config` at the very top of `.zshrc` —
   before atuin and other tool init, so a stale value inherited from a parent
   process (e.g. an old tmux server) can't break them.

6. **Git style:** Informal commit messages. No conventional commits enforced. No
   pre-commit hooks. Remote is GitHub under user `therobertgrigorian`.

7. **Neovim leader is Space**, set in both `options.lua` and `plugins/init.lua`.
   Always use `<leader>` prefix for custom keymaps, not hardcoded Space.

8. **Known typo:** The colorscheme file is named `coloscheme.lua` (missing 'r').
   Do not rename it without updating the import path.

9. **Plugin event loading:** Use `event = "VeryLazy"` or `event = "BufEnter"` for
   non-critical plugins to keep startup fast.

