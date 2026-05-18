#!/usr/bin/env bash
set -euo pipefail

# install.sh — installs video-tools (video-converter, tomp4) to $PREFIX
# Defaults to $HOME/.local. Override with PREFIX=/some/path ./install.sh
#
# Also runnable via:
#   curl -fsSL https://raw.githubusercontent.com/wukerplank/video-tools/main/install.sh | bash

PROJECT_NAME="video-tools"
REPO_URL="https://github.com/wukerplank/video-tools.git"
SCRIPTS=(video-converter tomp4)

PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="$PREFIX/bin"
SHARE_DIR="$PREFIX/share/$PROJECT_NAME"

# Resolve the script's source dir. When piped via `curl | bash`, BASH_SOURCE is
# empty and this resolves to "" — that's our cue to bootstrap by cloning.
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" 2>/dev/null && pwd || true)"

if [ -z "$SOURCE_DIR" ] || [ ! -f "$SOURCE_DIR/libexec/video-converter" ]; then
  if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is required for the piped install. Install git first." >&2
    exit 1
  fi
  TMP_CLONE="$(mktemp -d)"
  trap 'rm -rf "$TMP_CLONE"' EXIT
  echo "Bootstrapping: cloning $REPO_URL into $TMP_CLONE"
  git clone --depth 1 "$REPO_URL" "$TMP_CLONE" >/dev/null
  exec bash "$TMP_CLONE/install.sh" "$@"
fi

bold() { printf "\033[1m%s\033[0m\n" "$*"; }
warn() { printf "\033[33m[warn]\033[0m %s\n" "$*"; }
error() { printf "\033[31m[error]\033[0m %s\n" "$*" >&2; }
info() { printf "[info] %s\n" "$*"; }

# 1. Detect OS
OS="$(uname -s)"
case "$OS" in
  Darwin) PLATFORM="macos" ;;
  Linux)  PLATFORM="linux" ;;
  *)
    error "Unsupported OS: $OS. This installer supports macOS and Linux only."
    exit 1
    ;;
esac

bold "Installing $PROJECT_NAME on $PLATFORM"
echo

# 2. Check Ruby
if ! command -v ruby >/dev/null 2>&1; then
  error "Ruby not found on PATH."
  echo "  Install Ruby first. Recommended:"
  echo "    - ruby-install: https://github.com/postmodern/ruby-install"
  echo "    - rbenv:        https://github.com/rbenv/rbenv"
  echo "    - asdf:         https://asdf-vm.com/"
  exit 1
fi

RUBY_VERSION="$(ruby -e 'print RUBY_VERSION')"
RUBY_MAJOR="${RUBY_VERSION%%.*}"
RUBY_MINOR_RAW="${RUBY_VERSION#*.}"
RUBY_MINOR="${RUBY_MINOR_RAW%%.*}"
if [ "$RUBY_MAJOR" -lt 2 ] || { [ "$RUBY_MAJOR" -eq 2 ] && [ "$RUBY_MINOR" -lt 7 ]; }; then
  error "Ruby >= 2.7 required, found $RUBY_VERSION"
  exit 1
fi
info "Ruby $RUBY_VERSION ✓"

# 3. Check Bundler
if ! command -v bundle >/dev/null 2>&1; then
  error "Bundler not found."
  echo "  Install it with:  gem install --user-install bundler"
  echo "  (modern Ruby ships with bundler — if you have Ruby ≥ 2.6 something is off)"
  exit 1
fi
info "Bundler $(bundle --version | awk '{print $NF}') ✓"

# 4. Check ffmpeg (required)
if command -v ffmpeg >/dev/null 2>&1; then
  info "ffmpeg $(ffmpeg -version 2>&1 | head -n1 | awk '{print $3}') ✓"
else
  warn "ffmpeg NOT found — the scripts will fail at runtime without it."
  case "$PLATFORM" in
    linux)
      echo "  Install with one of:"
      echo "    sudo apt install ffmpeg"
      echo "    sudo dnf install ffmpeg"
      echo "    sudo pacman -S ffmpeg"
      ;;
    macos)
      echo "  Download a static build from: https://evermeet.cx/ffmpeg/"
      echo "  Place the binary somewhere on your PATH (e.g. $BIN_DIR/ffmpeg)."
      ;;
  esac
fi

# 5. Check HandBrakeCLI (optional)
if command -v HandBrakeCLI >/dev/null 2>&1; then
  info "HandBrakeCLI $(HandBrakeCLI --version 2>&1 | head -n1 | awk '{print $NF}') ✓ (optional)"
else
  info "HandBrakeCLI not found (optional — falls back to ffmpeg)."
  case "$PLATFORM" in
    linux)
      echo "  Install with: sudo apt install handbrake-cli   (or distro equivalent)"
      ;;
    macos)
      echo "  Download from: https://handbrake.fr/downloads2.php"
      ;;
  esac
fi

echo

# 6. Set up dirs
info "Install prefix: $PREFIX"
info "  binaries  -> $BIN_DIR"
info "  payload   -> $SHARE_DIR"
mkdir -p "$BIN_DIR" "$SHARE_DIR"

# 7. Copy payload
info "Copying files to $SHARE_DIR …"
mkdir -p "$SHARE_DIR/libexec"
cp "$SOURCE_DIR/Gemfile" "$SHARE_DIR/"
[ -f "$SOURCE_DIR/Gemfile.lock" ] && cp "$SOURCE_DIR/Gemfile.lock" "$SHARE_DIR/"
cp "$SOURCE_DIR/libexec/video-converter" "$SHARE_DIR/libexec/"
cp "$SOURCE_DIR/libexec/tomp4"           "$SHARE_DIR/libexec/"
cp "$SOURCE_DIR/libexec/UserPresets.json" "$SHARE_DIR/libexec/"
chmod 755 "$SHARE_DIR/libexec/video-converter" "$SHARE_DIR/libexec/tomp4"

# 8. Bundle install
info "Installing Ruby gems into $SHARE_DIR/vendor/bundle …"
(
  cd "$SHARE_DIR"
  bundle config set --local path "vendor/bundle"
  bundle install --quiet
)

# 9. Symlink executables into $BIN_DIR
for name in "${SCRIPTS[@]}"; do
  link="$BIN_DIR/$name"
  target="$SHARE_DIR/libexec/$name"
  info "Linking: $link -> $target"
  ln -sf "$target" "$link"
done

echo

# 10. PATH check
case ":$PATH:" in
  *":$BIN_DIR:"*)
    info "$BIN_DIR is on your PATH ✓"
    ;;
  *)
    warn "$BIN_DIR is NOT on your PATH."
    echo "  Add this to your ~/.zshrc or ~/.bashrc:"
    echo "    export PATH=\"$BIN_DIR:\$PATH\""
    ;;
esac

echo
bold "Done."
echo "Try:  video-converter --help"
echo "      tomp4              # prints usage"
