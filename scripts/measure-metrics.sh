#!/bin/bash

# Overdrive Build Metrics Measurement Script
# This script measures various metrics before and after scope reduction

set -e

echo "=== Overdrive Build Metrics Measurement ==="
echo "Timestamp: $(date)"
echo "Git commit: $(git rev-parse HEAD)"
echo "Git branch: $(git branch --show-current)"
echo ""

# Function to measure directory size
measure_directory_size() {
    local dir="$1"
    local name="$2"
    if [ -d "$dir" ]; then
        local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo "$name: $size"
    else
        echo "$name: Not found"
    fi
}

# Function to count files
count_files() {
    local dir="$1"
    local name="$2"
    local pattern="$3"
    if [ -d "$dir" ]; then
        local count=$(find "$dir" -name "$pattern" -type f 2>/dev/null | wc -l)
        echo "$name: $count files"
    else
        echo "$name: Directory not found"
    fi
}

# Measure codebase size
echo "=== Codebase Size ==="
measure_directory_size "." "Total repository"
measure_directory_size "apps" "Applications directory"
measure_directory_size "core" "Core Rust library"
measure_directory_size "crates" "Shared Rust crates"
measure_directory_size "packages" "Node.js packages"
measure_directory_size "interface" "Interface components"
echo ""

# Count files by type
echo "=== File Counts ==="
count_files "." "Rust files" "*.rs"
count_files "." "TypeScript files" "*.ts"
count_files "." "TypeScript React files" "*.tsx"
count_files "." "JavaScript files" "*.js"
count_files "." "JSON files" "*.json"
count_files "." "TOML files" "*.toml"
echo ""

# Measure individual applications
echo "=== Application Sizes ==="
measure_directory_size "apps/desktop" "Desktop app"
measure_directory_size "apps/mobile" "Mobile app (React Native)"
measure_directory_size "apps/web" "Web app"
measure_directory_size "apps/landing" "Landing page"
measure_directory_size "apps/server" "Server app"
measure_directory_size "apps/storybook" "Storybook"
echo ""

# Count dependencies
echo "=== Dependencies ==="
if [ -f "Cargo.toml" ]; then
    cargo_members=$(grep -E '^\s*"[^"]*"' Cargo.toml | wc -l)
    echo "Cargo workspace members: $cargo_members"
fi

if [ -f "package.json" ]; then
    if command -v jq >/dev/null 2>&1; then
        npm_deps=$(jq -r '.devDependencies // {} | keys | length' package.json 2>/dev/null || echo "0")
        echo "Root npm devDependencies: $npm_deps"
    else
        echo "Root npm devDependencies: jq not available"
    fi
fi

# Count total package.json files
package_json_count=$(find . -name "package.json" -type f | wc -l)
echo "Total package.json files: $package_json_count"
echo ""

# Measure build artifacts if they exist
echo "=== Build Artifacts ==="
measure_directory_size "target" "Rust build artifacts"
measure_directory_size "node_modules" "Node.js dependencies"
measure_directory_size "apps/desktop/dist" "Desktop app dist"
echo ""

echo "=== Measurement Complete ==="
