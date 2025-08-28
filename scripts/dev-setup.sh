#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
  echo -e "${BLUE}$1${NC}"
}

success() {
  echo -e "${GREEN}$1${NC}"
}

warn() {
  echo -e "${YELLOW}$1${NC}"
}

error() {
  echo -e "${RED}$1${NC}"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

main() {
    info "Overdrive Development Setup"
    info "=========================="
    echo

    # Check if we're in the right directory
    if [ ! -f "$PROJECT_ROOT/Cargo.toml" ] || [ ! -f "$PROJECT_ROOT/package.json" ]; then
        error "Error: This doesn't appear to be the Overdrive project root."
        error "Please run this script from the Overdrive project directory."
        exit 1
    fi

    cd "$PROJECT_ROOT"

    case "${1:-setup}" in
        "validate"|"check")
            info "Running environment validation..."
            if [ -x "./scripts/validate-environment.sh" ]; then
                ./scripts/validate-environment.sh
            else
                error "Validation script not found or not executable"
                exit 1
            fi
            ;;
        "setup")
            info "Setting up development environment..."

            # Run the Overdrive-specific setup
            if [ -x "./scripts/setup-overdrive.sh" ]; then
                ./scripts/setup-overdrive.sh "${2:-}"
            else
                warn "Overdrive setup script not found, falling back to original setup script"
                if [ -x "./scripts/setup.sh" ]; then
                    ./scripts/setup.sh
                else
                    error "No setup script found"
                    exit 1
                fi
            fi

            echo
            info "Installing Node.js dependencies..."
            if command -v pnpm >/dev/null 2>&1; then
                pnpm i
            else
                error "pnpm not found. Please install pnpm first: https://pnpm.io/installation"
                exit 1
            fi

            echo
            info "Preparing build environment..."
            pnpm prep

            echo
            success "Setup complete!"
            info "Run './scripts/dev-setup.sh validate' to verify your setup"
            info "Run 'pnpm tauri dev' to start development"
            ;;
        "android")
            info "Setting up for Android development..."
            if [ -x "./scripts/setup-overdrive.sh" ]; then
                ./scripts/setup-overdrive.sh android
            else
                error "Overdrive setup script not found"
                exit 1
            fi
            ;;
        "help"|"-h"|"--help")
            echo "Overdrive Development Setup Script"
            echo
            echo "Usage: $0 [command]"
            echo
            echo "Commands:"
            echo "  setup     Set up the development environment (default)"
            echo "  android   Set up for Android development"
            echo "  validate  Validate the current environment"
            echo "  check     Alias for validate"
            echo "  help      Show this help message"
            echo
            echo "Examples:"
            echo "  $0                    # Set up development environment"
            echo "  $0 setup              # Same as above"
            echo "  $0 android            # Set up for Android development"
            echo "  $0 validate           # Check if environment is ready"
            ;;
        *)
            error "Unknown command: $1"
            echo "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

main "$@"
