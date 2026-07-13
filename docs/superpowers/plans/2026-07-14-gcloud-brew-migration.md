# gcloud → Homebrew Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the deleted `~/Downloads/google-cloud-sdk` install with a Homebrew-managed gcloud CLI, keep existing gcloud auth/config state, and make sure gcloud secrets can never be committed to the dotfiles repo.

**Architecture:** Three independent config changes, one commit each: (1) `.gitignore` entries that shield `~/.config/gcloud` (OAuth tokens) and `~/.config/homebrew` from git — these land inside the repo because `~/.config` is a symlink to `~/.dotfiles/.config`; (2) `cask "gcloud-cli"` in the Brewfile plus the actual install; (3) `.zshrc` lines that the old SDK installer appended (pointing at the now-deleted Downloads path) replaced with a completion-source block for the brew cask location.

**Tech Stack:** git, Homebrew (cask `gcloud-cli`), zsh.

## Global Constraints

- Repo root: `/Users/robertgrigorian/.dotfiles` (this IS the user's home-dir dotfiles repo; `~/.config` → symlink → `~/.dotfiles/.config`).
- **NEVER run `git add .config/gcloud` or `git add -A` / `git add .` before Task 1 is committed** — `.config/gcloud/` contains live OAuth credentials (`credentials.db`, `access_tokens.db`, `legacy_credentials/dev.robert.grigoryan@gmail.com/adc.json`). Stage files by explicit path only.
- Do not delete or modify anything inside `.config/gcloud/` — it holds working auth state (account `dev.robert.grigoryan@gmail.com`, project `moonlit-bucksaw-478911-b4`) that the new install must pick up.
- Homebrew prefix is `/opt/homebrew` (Apple Silicon). `HOMEBREW_PREFIX` is exported by `.zprofile` line 2 (`eval "$(/opt/homebrew/bin/brew shellenv)"`), which only runs in login shells — hence the `${HOMEBREW_PREFIX:-/opt/homebrew}` fallback used in Task 3.
- Commit messages: conventional style, lowercase (`chore(...): ...`), matching repo history.
- A shell-command rewrite hook (rtk) transparently proxies commands like `git status`; run commands as written, no adjustment needed.

---

### Task 1: Shield gcloud secrets and homebrew state from git

**Files:**
- Modify: `.gitignore` (append after line 35, `.config/raycast-x/`)

**Interfaces:**
- Consumes: nothing (first task).
- Produces: `git status` no longer lists `.config/gcloud/` or `.config/homebrew/` as untracked; later tasks may safely stage-by-path without secret-leak risk.

- [ ] **Step 1: Verify current (unprotected) state**

Run: `git -C /Users/robertgrigorian/.dotfiles check-ignore .config/gcloud/credentials.db; echo "exit=$?"`
Expected: no path printed, `exit=1` (file is NOT ignored yet — this is the "failing test").

- [ ] **Step 2: Append ignore rules**

Append to the end of `/Users/robertgrigorian/.dotfiles/.gitignore` (after the `.config/raycast-x/` line):

```gitignore

# Google Cloud SDK state — OAuth tokens, credentials, virtualenv, logs
.config/gcloud/

# Homebrew trust store — per-machine state
.config/homebrew/
```

- [ ] **Step 3: Verify rules work**

Run: `git -C /Users/robertgrigorian/.dotfiles check-ignore -v .config/gcloud/credentials.db .config/homebrew/trust.json.lock`
Expected: two lines, each showing `.gitignore:<line>` with patterns `.config/gcloud/` and `.config/homebrew/`.

Run: `git -C /Users/robertgrigorian/.dotfiles status --short`
Expected: `M .zshrc` and `?? docs/` may appear; `?? .config/gcloud/` and `?? .config/homebrew/` must NOT appear.

- [ ] **Step 4: Commit**

```bash
git -C /Users/robertgrigorian/.dotfiles add .gitignore
git -C /Users/robertgrigorian/.dotfiles commit -m "chore(git): ignore gcloud state and homebrew trust dirs"
```

---

### Task 2: Install gcloud CLI via Homebrew cask

**Files:**
- Modify: `Brewfile` (insert between line 65 `cask "font-symbols-only-nerd-font"` and line 66 `cask "ghostty"` — casks are alphabetical)

**Interfaces:**
- Consumes: nothing from Task 1 (independent), but run after it so no staging accident is possible.
- Produces: `gcloud`, `gsutil`, `bq` binaries symlinked into `/opt/homebrew/bin` (already on PATH); SDK files at `/opt/homebrew/share/google-cloud-sdk/` — Task 3's `.zshrc` block sources `completion.zsh.inc` from there.

- [ ] **Step 1: Verify gcloud absent**

Run: `which gcloud; echo "exit=$?"`
Expected: `gcloud not found`, `exit=1`.

- [ ] **Step 2: Add cask to Brewfile**

In `/Users/robertgrigorian/.dotfiles/Brewfile`, insert one line so the cask block reads:

```ruby
cask "font-symbols-only-nerd-font"
cask "gcloud-cli"
cask "ghostty"
```

- [ ] **Step 3: Install the cask**

Run: `brew install --cask gcloud-cli`
Expected: ends with `🍺  gcloud-cli was successfully installed!` (downloads ~sdk, runs its install.sh; python@3.14 dependency already present). Takes a few minutes.

- [ ] **Step 4: Verify install and preserved auth**

Run: `gcloud --version`
Expected: `Google Cloud SDK 575.0.1` (or newer) plus component lines — works in the current shell because `/opt/homebrew/bin` is already on PATH.

Run: `gcloud auth list`
Expected: table listing `dev.robert.grigoryan@gmail.com` with `*` (active) — old `~/.config/gcloud` state picked up, no re-login.

Run: `gcloud config get-value project`
Expected: `moonlit-bucksaw-478911-b4`.

Run: `gcloud auth print-access-token >/dev/null 2>&1 && echo AUTH-OK || echo AUTH-DEAD`
Expected: `AUTH-OK` (refresh token still valid). If `AUTH-DEAD`: token was revoked while SDK was gone — run `gcloud auth login` once (opens browser), then re-run and expect `AUTH-OK`.

- [ ] **Step 5: Commit**

```bash
git -C /Users/robertgrigorian/.dotfiles add Brewfile
git -C /Users/robertgrigorian/.dotfiles commit -m "chore(brew): add gcloud-cli cask"
```

---

### Task 3: Point .zshrc at the brew cask instead of Downloads

**Files:**
- Modify: `.zshrc:116-121` (the 6 uncommitted lines the old SDK installer appended: one blank line + PATH comment/if + blank line + completion comment/if, all referencing the deleted `/Users/robertgrigorian/Downloads/google-cloud-sdk`)

**Interfaces:**
- Consumes: `/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc` installed by Task 2.
- Produces: final `.zshrc` state; nothing downstream.

- [ ] **Step 1: Verify the completion file exists at the brew path**

Run: `ls /opt/homebrew/share/google-cloud-sdk/completion.zsh.inc`
Expected: the path echoed back (file exists). If missing, stop — Task 2 did not complete.

- [ ] **Step 2: Replace the installer lines**

In `/Users/robertgrigorian/.dotfiles/.zshrc`, replace these 6 lines (currently 116–121, at end of file):

```zsh

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/robertgrigorian/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/robertgrigorian/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/robertgrigorian/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/robertgrigorian/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
```

with:

```zsh

# Google Cloud SDK (brew cask gcloud-cli): binaries are on PATH via brew;
# only shell completion needs sourcing.
if [ -f "${HOMEBREW_PREFIX:-/opt/homebrew}/share/google-cloud-sdk/completion.zsh.inc" ]; then
  . "${HOMEBREW_PREFIX:-/opt/homebrew}/share/google-cloud-sdk/completion.zsh.inc"
fi
```

No `path.zsh.inc` equivalent is needed: the cask symlinks `gcloud`/`gsutil`/`bq` into `/opt/homebrew/bin`, which `.zprofile` already puts on PATH. The `-f` guard keeps `.zshrc` working on machines without the cask. `${HOMEBREW_PREFIX:-/opt/homebrew}` covers non-login shells where `.zprofile` didn't run.

- [ ] **Step 3: Verify a fresh login shell resolves gcloud and loads completion**

Run: `zsh -ilc 'which gcloud; print -r -- ${_comps[gcloud]:-MISSING}' 2>/dev/null | tail -2`
Expected: `/opt/homebrew/bin/gcloud` and a completion function name (NOT `MISSING`; typically a `_bash_complete`/argcomplete wrapper).

Run: `zsh -ilc 'exit' 2>&1 | grep -i "no such file\|command not found"; echo "exit=$?"`
Expected: no output, `exit=1` (startup produces no errors from the new block).

- [ ] **Step 4: Commit**

```bash
git -C /Users/robertgrigorian/.dotfiles add .zshrc
git -C /Users/robertgrigorian/.dotfiles commit -m "chore(zsh): source gcloud completion from brew cask"
```

Run: `git -C /Users/robertgrigorian/.dotfiles status --short`
Expected: only `?? docs/` remains (this plan file — commit or delete it at the user's discretion).
