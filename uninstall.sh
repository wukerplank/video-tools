#!/usr/bin/env bash
set -euo pipefail

# uninstall.sh — removes video-tools from $PREFIX (default: $HOME/.local).

PROJECT_NAME="video-tools"
SCRIPTS=(video-converter tomp4)

PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="$PREFIX/bin"
SHARE_DIR="$PREFIX/share/$PROJECT_NAME"

info() { printf "[info] %s\n" "$*"; }

for name in "${SCRIPTS[@]}"; do
  if [ -L "$BIN_DIR/$name" ] || [ -f "$BIN_DIR/$name" ]; then
    info "Removing $BIN_DIR/$name"
    rm -f "$BIN_DIR/$name"
  fi
done

if [ -d "$SHARE_DIR" ]; then
  info "Removing $SHARE_DIR"
  rm -rf "$SHARE_DIR"
fi

info "Done."
