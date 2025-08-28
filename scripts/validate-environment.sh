#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
WARNINGS=0

# Helper functions
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((CHECKS_PASSED++))
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((CHECKS_FAILED++))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

check_command() {
    local cmd=$1
    local name=${2:-$cmd}
    local required=${3:-true}

    if command -v "$cmd" >/dev/null 2>&1; then
        local version
        case $cmd in
            "rustc")
                version=$(rustc --version | cut -d' ' -f2)
                ;;
            "node")
                version=$(node --version)
                ;;
            "pnpm")
                version=$(pnpm --version)
                ;;
            "cargo")
                version=$(cargo --version | cut -d' ' -f2)
                ;;
            *)
                version="installed"
                ;;
        esac
        print_success "$name found: $version"
        return 0
    else
        if [ "$required" = true ]; then
            print_error "$name not found"
            return 1
        else
            print_warning "$name not found (optional)"
            return 1
        fi
    fi
}

check_version() {
    local cmd=$1
    local min_version=$2
    local name=${3:-$cmd}

    if ! command -v "$cmd" >/dev/null 2>&1; then
        print_error "$name not found"
        return 1
    fi

    local current_version
    case $cmd in
        "rustc")
            current_version=$(rustc --version | cut -d' ' -f2)
            ;;
        "node")
            current_version=$(node --version | sed 's/v//')
            ;;
        "pnpm")
            current_version=$(pnpm --version)
            ;;
        *)
            print_warning "Version check not implemented for $name"
            return 0
            ;;
    esac

    if [ "$(printf '%s\n' "$min_version" "$current_version" | sort -V | head -n1)" = "$min_version" ]; then
        print_success "$name version $current_version (>= $min_version required)"
        return 0
    else
        print_error "$name version $current_version is too old (>= $min_version required)"
        return 1
    fi
}

check_file_exists() {
    local file=$1
    local description=${2:-$file}

    if [ -f "$file" ]; then
        print_success "$description exists"
        return 0
    else
        print_error "$description not found: $file"
        return 1
    fi
}

check_directory_exists() {
    local dir=$1
    local description=${2:-$dir}

    if [ -d "$dir" ]; then
        print_success "$description exists"
        return 0
    else
        print_error "$description not found: $dir"
        return 1
    fi
}

# Main validation
main() {
    echo -e "${BLUE}Overdrive Development Environment Validation${NC}"
    echo "=============================================="

    print_header "Basic Dependencies"

    # Check Rust toolchain
    check_version "rustc" "1.81.0" "Rust compiler"
    check_version "cargo" "1.81.0" "Cargo package manager"

    # Check Node.js and pnpm
    check_version "node" "18.18.0" "Node.js"
    check_version "pnpm" "9.4.0" "pnpm package manager"

    # Check optional but useful tools
    check_command "git" "Git" false
    check_command "clang" "Clang compiler" false
    check_command "lld" "LLD linker" false

    print_header "Project Structure"

    # Check essential project files
    check_file_exists "Cargo.toml" "Root Cargo.toml"
    check_file_exists "package.json" "Root package.json"
    check_file_exists "core/Cargo.toml" "Core Cargo.toml"
    check_file_exists "core/prisma/schema.prisma" "Prisma schema"
    check_file_exists "apps/desktop/src-tauri/Cargo.toml" "Desktop app Cargo.toml"

    # Check essential directories
    check_directory_exists "core" "Core directory"
    check_directory_exists "crates" "Crates directory"
    check_directory_exists "apps/desktop" "Desktop app directory"
    check_directory_exists "interface" "Interface directory"

    print_header "Generated Code"

    # Check Prisma generated files
    check_file_exists "crates/prisma/src/prisma/mod.rs" "Prisma client (main)"
    check_file_exists "crates/prisma/src/prisma/_prisma.rs" "Prisma client (core)"
    check_file_exists "crates/prisma/src/prisma_sync/mod.rs" "Prisma sync generator"

    print_header "Node.js Dependencies"

    # Check if node_modules exists
    if [ -d "node_modules" ]; then
        print_success "Node.js dependencies installed"

        # Check for key dependencies
        if [ -d "node_modules/@tauri-apps" ]; then
            print_success "Tauri dependencies found"
        else
            print_warning "Tauri dependencies not found in node_modules"
        fi

        if [ -f "node_modules/.bin/prisma" ]; then
            print_success "Prisma CLI available"
        else
            print_warning "Prisma CLI not found"
        fi
    else
        print_error "Node.js dependencies not installed (run 'pnpm i')"
    fi

    print_header "Cargo Dependencies"

    # Check if Cargo.lock exists
    if [ -f "Cargo.lock" ]; then
        print_success "Cargo.lock exists"
    else
        print_warning "Cargo.lock not found (dependencies may not be resolved)"
    fi

    # Check if target directory exists
    if [ -d "target" ]; then
        print_success "Target directory exists"

        # Check for built binaries
        if [ -f "target/debug/prisma" ]; then
            print_success "Prisma CLI binary built"
        else
            print_info "Prisma CLI binary not built (will be built on first use)"
        fi
    else
        print_info "Target directory not found (will be created on first build)"
    fi

    print_header "System Dependencies (Linux)"

    # Check Linux-specific dependencies for Tauri
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Essential build tools
        check_command "gcc" "GCC compiler" false
        check_command "pkg-config" "pkg-config" false

        # GTK and WebKit dependencies
        if pkg-config --exists gtk+-3.0 2>/dev/null; then
            print_success "GTK+ 3.0 development libraries found"
        else
            print_warning "GTK+ 3.0 development libraries not found"
            print_info "Install with: sudo apt install libgtk-3-dev (Ubuntu/Debian)"
        fi

        if pkg-config --exists webkit2gtk-4.1 2>/dev/null; then
            print_success "WebKit2GTK development libraries found"
        else
            print_warning "WebKit2GTK development libraries not found"
            print_info "Install with: sudo apt install libwebkit2gtk-4.1-dev (Ubuntu/Debian)"
        fi

        # Additional Tauri dependencies
        if pkg-config --exists openssl 2>/dev/null; then
            print_success "OpenSSL development libraries found"
        else
            print_warning "OpenSSL development libraries not found"
            print_info "Install with: sudo apt install libssl-dev (Ubuntu/Debian)"
        fi
    else
        print_info "Skipping Linux-specific dependency checks (not on Linux)"
    fi

    print_header "Build Test"

    # Test if we can compile the core
    print_info "Testing Rust core compilation..."
    if timeout 30 cargo check -p sd-core --quiet 2>/dev/null; then
        print_success "Rust core compiles successfully"
    else
        print_error "Rust core compilation failed"
        print_info "Run 'cargo check -p sd-core' for detailed error information"
    fi

    # Test if we can run pnpm commands
    print_info "Testing pnpm workspace..."
    if timeout 10 pnpm --version >/dev/null 2>&1; then
        print_success "pnpm workspace accessible"
    else
        print_error "pnpm workspace test failed"
    fi

    print_header "Summary"

    echo -e "\nValidation Results:"
    echo -e "  ${GREEN}Passed: $CHECKS_PASSED${NC}"
    echo -e "  ${RED}Failed: $CHECKS_FAILED${NC}"
    echo -e "  ${YELLOW}Warnings: $WARNINGS${NC}"

    if [ $CHECKS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}✓ Environment validation passed!${NC}"
        echo -e "Your development environment is ready for Overdrive development."

        if [ $WARNINGS -gt 0 ]; then
            echo -e "\n${YELLOW}Note: There are $WARNINGS warnings above.${NC}"
            echo -e "These are optional dependencies that may improve your development experience."
        fi

        echo -e "\nNext steps:"
        echo -e "  1. Run 'pnpm tauri dev' to start the development server"
        echo -e "  2. The app should launch and be ready for development"

        return 0
    else
        echo -e "\n${RED}✗ Environment validation failed!${NC}"
        echo -e "Please address the $CHECKS_FAILED failed checks above before proceeding."

        echo -e "\nCommon fixes:"
        echo -e "  • Install missing dependencies with the setup script: ./scripts/setup.sh"
        echo -e "  • Install Node.js dependencies: pnpm i"
        echo -e "  • Update Rust: rustup update"
        echo -e "  • Update Node.js: use your preferred Node.js version manager"

        return 1
    fi
}

# Run main function
main "$@"
