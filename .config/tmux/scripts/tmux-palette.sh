#!/usr/bin/env bash
# Fast launcher for tmux-palette.
#
# The plugin's own launcher runs a blocking `bun --measure` pass BEFORE the
# popup appears, then starts bun a second time inside the popup. Bun's
# cold-start floor is ~0.26s, so that doubles the latency and leaves the
# screen blank during the measure pass. This launcher skips the measure
# pass: it opens the popup immediately at a fixed size, so bun starts only
# once and the popup chrome shows instantly.
#
# Lives in the dotfiles (not the plugin's bin/) so it survives TPM updates.
set -euo pipefail

TMUX_BIN="$(command -v tmux)"
DIR="$HOME/.config/tmux/plugins/tmux-palette"
CMD_FILE="$(mktemp)"
trap 'rm -f "$CMD_FILE"' EXIT

PALETTE="${1:-commands}"
shift || true
EXTRA_ARGS=("$@")

# Client size (one cheap tmux call, no bun).
CH="$($TMUX_BIN display-message -p '#{client_height}' 2>/dev/null || echo 24)"
CW="$($TMUX_BIN display-message -p '#{client_width}' 2>/dev/null || echo 80)"

# Fixed target size, capped to the client. Env overrides win.
WANT_H=20
WANT_W=90
WANT_PADX=3
MAX_H=$(( CH - 2 ))
H=$(( WANT_H > MAX_H ? MAX_H : WANT_H ))
W=$(( WANT_W > CW - 4 ? CW - 4 : WANT_W ))

# Mobile / very narrow: go edge-to-edge.
if [ "$CW" -lt 80 ]; then H="$CH"; W="$CW"; WANT_PADX=1; fi

H="${TMUX_PALETTE_HEIGHT:-$H}"
W="${TMUX_PALETTE_WIDTH:-$W}"

# Catppuccin Mocha popup body style (matches theme.json: catppuccin-mocha).
BODY_STYLE="bg=#1e1e2e"

# Build shell-safe argv (palette + forwarded flags).
ARG_STR=""
for a in "$PALETTE" ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}; do
  ARG_STR+=" $(printf %q "$a")"
done

$TMUX_BIN display-popup -B -s "$BODY_STYLE" -w "$W" -h "$H" -E \
  "TMUX_PALETTE_CMD='$CMD_FILE' TMUX_PALETTE_BIN='$0' TMUX_PALETTE_PADX='$WANT_PADX' TMUX_PALETTE_BORDERED='0' exec bun '$DIR/src/cli.ts'$ARG_STR"

if [ -s "$CMD_FILE" ]; then
  CMD="$(cat "$CMD_FILE")"
  case "$CMD" in
    tmux:*)  eval "$TMUX_BIN ${CMD#tmux:}" || true ;;
    shell:*) eval "${CMD#shell:}" || true ;;
  esac
fi
exit 0
