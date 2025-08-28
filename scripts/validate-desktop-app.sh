#!/bin/bash

# Overdrive Desktop App Validation Script
# This script validates that the desktop app still builds and runs after changes

set -e

echo "=== Overdrive Desktop App Validation ==="
echo "Timestamp: $(date)"
echo ""

# Function to check if command succeeded
check_command() {
    local cmd="$1"
    local description="$2"

    echo "Testing: $description"
    if eval "$cmd" >/dev/null 2>&1; then
        echo "✅ PASS: $description"
        return 0
    else
        echo "❌ FAIL: $description"
        return 1
    fi
}

# Test workspace integrity
echo "=== Workspace Validation ==="
check_command "pnpm install --frozen-lockfile" "pnpm install"
check_command "pnpm prep" "Prisma generation and codegen"
echo ""

# Test build system
echo "=== Build System Validation ==="
check_command "cargo check -p sd-core" "Rust core compilation check"
check_command "pnpm desktop typecheck" "TypeScript type checking"
check_command "pnpm desktop build" "Desktop app build"
echo ""

# Test that essential files exist
echo "=== Essential Files Check ==="
essential_files=(
    "apps/desktop/package.json"
    "apps/desktop/src-tauri/Cargo.toml"
    "core/Cargo.toml"
    "packages/client/package.json"
    "packages/ui/package.json"
    "interface/package.json"
)

for file in "${essential_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ FOUND: $file"
    else
        echo "❌ MISSING: $file"
    fi
done
echo ""

echo "=== Validation Complete ==="
