#!/usr/bin/env bash

set -euo pipefail

if [ "${CI:-}" = "true" ]; then
  set -x
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

err() {
  for _line in "$@"; do
    echo -e "${RED}$_line${NC}" >&2
  done
  exit 1
}

info() {
  echo -e "${BLUE}$1${NC}"
}

success() {
  echo -e "${GREEN}$1${NC}"
}

warn() {
  echo -e "${YELLOW}$1${NC}"
}

has() {
  for prog in "$@"; do
    if ! command -v "$prog" 1>/dev/null 2>&1; then
      return 1
    fi
  done
}

sudo() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    env sudo "$@"
  fi
}

script_failure() {
  if [ -n "${1:-}" ]; then
    _line="on line $1"
  else
    _line="(unknown)"
  fi
  err "An error occurred $_line." "Setup failed."
}

trap 'script_failure ${LINENO:-}' ERR

case "${OSTYPE:-}" in
  'msys' | 'mingw' | 'cygwin')
    err 'Bash for windows is not supported.' \
        'Overdrive focuses on Linux and Android only.' \
        'Please use a Linux system or WSL2 for development.'
    ;;
esac

if [ "${CI:-}" != "true" ]; then
  info 'Overdrive Development Environment Setup'
  info '========================================'
  info 'This script will set up your Linux system for Overdrive development.'
  info 'Overdrive is focused on Linux desktop and Android platforms only.'
  echo
  info 'Press Enter to continue, or Ctrl+C to cancel'
  read -r

  # Check for required tools
  if ! has pnpm; then
    err 'pnpm was not found.' \
      "Ensure the 'pnpm' command is in your \$PATH." \
      'You must use pnpm for this project; yarn and npm are not allowed.' \
      'Install pnpm: https://pnpm.io/installation'
  fi

  if ! has rustc cargo; then
    err 'Rust was not found.' \
      "Ensure the 'rustc' and 'cargo' binaries are in your \$PATH." \
      'Install Rust: https://rustup.rs'
  fi

  # Check Rust version
  RUST_VERSION=$(rustc --version | cut -d' ' -f2)
  REQUIRED_RUST="1.81.0"
  if [ "$(printf '%s\n' "$REQUIRED_RUST" "$RUST_VERSION" | sort -V | head -n1)" != "$REQUIRED_RUST" ]; then
    err "Rust version $RUST_VERSION is too old." \
        "Overdrive requires Rust >= $REQUIRED_RUST" \
        'Update Rust: rustup update'
  fi

  # Check Node.js version
  if has node; then
    NODE_VERSION=$(node --version | sed 's/v//')
    REQUIRED_NODE="18.18.0"
    if [ "$(printf '%s\n' "$REQUIRED_NODE" "$NODE_VERSION" | sort -V | head -n1)" != "$REQUIRED_NODE" ]; then
      warn "Node.js version $NODE_VERSION may be too old (>= $REQUIRED_NODE recommended)"
    fi
  fi

  echo
fi

# Install rust deps for android if requested
if [ "${1:-}" = "android" ]; then
  ANDROID=1
  info "Setting up for Android development..."

  # Android requires python
  if ! { has python3 || { has python && python -c 'import sys; exit(0 if sys.version_info[0] == 3 else 1)'; }; }; then
    err 'python3 was not found.' \
      'This is required for Android development.' \
      "Ensure 'python3' is available in your \$PATH and try again."
  fi

  if ! has rustup; then
    err 'Rustup was not found. It is required for cross-compiling rust to Android targets.' \
      "Ensure the 'rustup' binary is in your \$PATH." \
      'https://rustup.rs'
  fi

  # Android targets
  info "Installing Android targets for Rust..."
  rustup target add \
    aarch64-linux-android \
    armv7-linux-androideabi \
    x86_64-linux-android

  echo
else
  ANDROID=0
fi

# Install system deps for Linux
case "$(uname)" in
  "Linux")
    info "Detected Linux system"

    # Detect package manager and install dependencies
    if has apt-get; then
      info "Detected apt package manager"
      info "Installing dependencies with apt..."

      # Tauri dependencies for Linux
      set -- build-essential curl wget file openssl libssl-dev libgtk-3-dev librsvg2-dev \
        libwebkit2gtk-4.1-dev libayatana-appindicator3-dev libxdo-dev libdbus-1-dev

      # Webkit2gtk requires gstreamer plugins for video playback
      set -- "$@" gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev

      # C/C++ build dependencies, required to build some *-sys crates
      set -- "$@" llvm-dev libclang-dev clang nasm perl

      # React dependencies
      set -- "$@" libvips42

      sudo apt-get -y update
      sudo apt-get -y install "$@"

    elif has pacman; then
      info "Detected pacman package manager"
      info "Installing dependencies with pacman..."

      # Tauri dependencies
      set -- base-devel curl wget file openssl gtk3 librsvg webkit2gtk-4.1 libayatana-appindicator xdotool dbus

      # Webkit2gtk requires gstreamer plugins for video playback
      set -- "$@" gst-plugins-base gst-plugins-good gst-plugins-ugly

      # C/C++ build dependencies
      set -- "$@" clang nasm perl

      # React dependencies
      set -- "$@" libvips

      sudo pacman -Sy --needed "$@"

    elif has dnf; then
      info "Detected dnf package manager"
      info "Installing dependencies with dnf..."

      # Development tools
      if ! { sudo dnf group install "C Development Tools and Libraries" || sudo dnf group install "Development Tools"; }; then
        err 'We were unable to install the "C Development Tools and Libraries"/"Development Tools" package.' \
          'Please open an issue if you feel that this is incorrect.' \
          'https://github.com/spacedriveapp/spacedrive/issues'
      fi

      # Tauri dependencies
      set -- openssl webkit2gtk4.1-devel openssl-devel curl wget file libappindicator-gtk3-devel librsvg2-devel libxdo-devel dbus-devel

      # Webkit2gtk requires gstreamer plugins for video playback
      set -- "$@" gstreamer1-devel gstreamer1-plugins-base-devel gstreamer1-plugins-good \
        gstreamer1-plugins-good-extras gstreamer1-plugins-ugly-free

      # C/C++ build dependencies
      set -- "$@" clang clang-devel nasm perl-core

      # React dependencies
      set -- "$@" vips

      sudo dnf install "$@"

    else
      if has lsb_release; then
        _distro="'$(lsb_release -s -d)' "
      fi
      err "Your Linux distro ${_distro:-}is not supported by this script." \
        'Overdrive focuses on common Linux distributions.' \
        'You may need to manually install the equivalent packages for your system.' \
        'Required: GTK3, WebKit2GTK, OpenSSL, build tools, and development headers.'
    fi
    ;;
  *)
    err "Your OS ($(uname)) is not supported by Overdrive." \
      'Overdrive is designed specifically for Linux desktop and Android.' \
      'Please use a Linux system for development.'
    ;;
esac

# Install Rust tools
if [ "${CI:-}" != "true" ]; then
  info "Installing Rust tools..."

  _tools="cargo-watch"
  if [ $ANDROID -eq 1 ]; then
    _tools="$_tools cargo-ndk" # For building Android
  fi

  echo "$_tools" | xargs cargo install
fi

# Validate the setup
info "Validating setup..."

# Check if we can compile the core
if timeout 30 cargo check -p sd-core --quiet 2>/dev/null; then
  success "✓ Rust core compiles successfully"
else
  warn "⚠ Rust core compilation test failed"
  info "This might be normal if dependencies aren't installed yet."
  info "Run 'pnpm i && pnpm prep' to install dependencies."
fi

# Final instructions
echo
success 'Overdrive development environment setup complete!'
echo
info 'Next steps:'
info '1. Install Node.js dependencies: pnpm i'
info '2. Prepare the build: pnpm prep'
info '3. Start development: pnpm tauri dev'
echo
if [ $ANDROID -eq 1 ]; then
  info 'Android development setup:'
  info '• Install Android Studio and SDK'
  info '• Set up Android NDK (version 26.1.10909125 recommended)'
  info '• Configure ANDROID_HOME and NDK environment variables'
  echo
fi
info 'For validation, run: ./scripts/validate-environment.sh'
info 'For help, see: CONTRIBUTING.md'
