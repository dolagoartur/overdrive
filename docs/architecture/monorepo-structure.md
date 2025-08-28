# Overdrive Monorepo Structure

This document provides a comprehensive overview of the Overdrive monorepo structure, dependencies, and build system organization.

## Overview

Overdrive is organized as a monorepo with both Rust (Cargo workspace) and Node.js (pnpm workspace) components. The project uses the "PRRTT" stack: **Prisma, Rust, React, TypeScript, Tauri**.

## Root Structure

```
overdrive/
├── apps/                    # Applications
├── core/                    # Rust core library
├── crates/                  # Shared Rust libraries
├── interface/               # React UI components
├── packages/                # Node.js packages
├── scripts/                 # Build and setup scripts
├── docs/                    # Documentation
├── Cargo.toml              # Rust workspace configuration
├── package.json            # Node.js workspace configuration
└── .kiro/                  # Kiro IDE configuration
```

## Applications (`apps/`)

### Desktop App (`apps/desktop/`)
- **Purpose**: Main Tauri-based desktop application for Linux
- **Technology**: Tauri 2.0.6 + React + TypeScript
- **Key Files**:
  - `src-tauri/Cargo.toml` - Rust backend configuration
  - `package.json` - Frontend dependencies
  - `src-tauri/src/main.rs` - Tauri application entry point

### Mobile App (`apps/mobile/`)
- **Status**: Will be replaced with Tauri for Android in Overdrive
- **Current**: React Native (to be removed)
- **Future**: Tauri-based Android app

### Web App (`apps/web/`)
- **Status**: To be removed in Overdrive (desktop/mobile focus only)
- **Current**: React web application

### Landing Page (`apps/landing/`)
- **Status**: To be removed in Overdrive (not needed for focused scope)
- **Current**: Next.js landing page

### Server (`apps/server/`)
- **Status**: To be removed in Overdrive (desktop app has embedded backend)
- **Current**: Standalone Rust server

### Storybook (`apps/storybook/`)
- **Status**: To be simplified in Overdrive
- **Current**: Component documentation

## Core Library (`core/`)

The heart of Overdrive - a pure Rust library containing all core functionality.

### Structure
```
core/
├── src/                    # Main library source
├── crates/                 # Core-specific sub-crates
├── prisma/                 # Database schema and migrations
├── Cargo.toml             # Core library configuration
└── build.rs               # Build script
```

### Core Sub-crates (`core/crates/`)
- `cloud-services/` - Cloud integration (may be removed)
- `file-path-helper/` - File path utilities
- `heavy-lifting/` - Resource-intensive operations
- `indexer-rules/` - File indexing rules
- `prisma-helpers/` - Database utilities
- `sync/` - Data synchronization

### Key Features
- **File System Operations**: Directory scanning, file metadata
- **Database Management**: SQLite with Prisma ORM
- **Networking**: P2P communication, sync protocols
- **Media Processing**: Thumbnail generation, metadata extraction

## Shared Crates (`crates/`)

Reusable Rust libraries used across the project.

### Essential Crates
- `actors/` - Actor system for concurrent operations
- `crypto/` - Cryptographic utilities
- `file-ext/` - File extension handling
- `images/` - Image processing and thumbnails
- `media-metadata/` - Media file metadata extraction
- `prisma/` - Generated Prisma client
- `sync/` - Synchronization protocols
- `task-system/` - Background task management
- `utils/` - Common utilities

### Platform-Specific Crates (to be removed)
- `ffmpeg/` - Video processing (optional feature)
- `ai/` - AI features (optional)

### Development Crates
- `prisma-cli/` - Custom Prisma generators
- `sync-generator/` - Sync code generation

## User Interface (`interface/`)

Shared React components and UI logic used by desktop and web apps.

### Structure
```
interface/
├── app/                   # Main application components
├── hooks/                 # React hooks
├── locales/              # Internationalization
├── components/           # Reusable UI components
└── package.json          # Dependencies
```

### Key Features
- **File Explorer**: Tree view, list view, file operations
- **Settings**: Application configuration UI
- **Search**: File search and filtering
- **Media Viewer**: Image and video preview

## Packages (`packages/`)

Node.js packages for build tools and shared utilities.

### Essential Packages
- `client/` - TypeScript client for RPC communication
- `ui/` - Shared React component library
- `config/` - ESLint, TypeScript configurations
- `assets/` - Shared images, fonts, icons

### Build Packages
- Scripts and utilities for build process

## Build System

### Cargo Workspace
Defined in root `Cargo.toml`:
- **Members**: All Rust crates and applications
- **Shared Dependencies**: Common versions and features
- **Build Profiles**: Development and release configurations

### pnpm Workspace
Defined in root `package.json`:
- **Workspaces**: All Node.js packages and apps
- **Scripts**: Build, development, and maintenance commands
- **Dependencies**: Shared Node.js dependencies

### Key Build Commands
```bash
# Install dependencies
pnpm i

# Prepare build (Prisma generation, etc.)
pnpm prep

# Development server
pnpm tauri dev

# Production build
pnpm build

# Rust-only operations
cargo build
cargo check
cargo test
```

## Dependency Flow

### Frontend → Backend Communication
```
React Components (interface/)
    ↓ (RPC calls)
TypeScript Client (packages/client/)
    ↓ (rspc protocol)
Tauri Commands (apps/desktop/src-tauri/)
    ↓ (function calls)
Rust Core (core/)
    ↓ (database operations)
Prisma Client (crates/prisma/)
    ↓ (SQL queries)
SQLite Database
```

### Build Dependencies
```
pnpm workspace
    ↓ (manages)
Node.js packages + React apps
    ↓ (builds with)
Tauri
    ↓ (embeds)
Rust workspace
    ↓ (compiles)
Native binary
```

## Key Technologies

### Rust Ecosystem
- **Tauri**: Desktop app framework
- **Prisma**: Database ORM (custom Rust client)
- **rspc**: Type-safe RPC between Rust and TypeScript
- **tokio**: Async runtime
- **serde**: Serialization

### Node.js Ecosystem
- **React**: UI framework
- **TypeScript**: Type-safe JavaScript
- **pnpm**: Package manager
- **Vite**: Build tool
- **ESLint**: Code linting

### Database
- **SQLite**: Local database
- **Prisma**: Schema management and migrations

## Overdrive-Specific Changes

### Components to Remove
- `apps/web/` - Web application
- `apps/landing/` - Landing page
- `apps/server/` - Standalone server
- `apps/mobile/` - React Native mobile app
- Platform-specific code for macOS/Windows/iOS

### Components to Modify
- `apps/desktop/` - Focus on Linux, prepare for Android
- `apps/storybook/` - Simplify or remove
- Build scripts - Remove non-Linux/Android targets

### Components to Retain
- `core/` - All core Rust functionality
- `crates/` - Essential shared libraries
- `interface/` - UI components (simplify)
- `packages/client/` - RPC communication
- `packages/ui/` - Component library (simplify)

## Development Workflow

1. **Setup**: Run setup scripts for Linux dependencies
2. **Install**: `pnpm i` for Node.js dependencies
3. **Prepare**: `pnpm prep` for code generation
4. **Develop**: `pnpm tauri dev` for hot-reload development
5. **Build**: `pnpm build` for production builds
6. **Test**: `cargo test` for Rust tests

This structure supports Overdrive's goals of safety, reliability, and performance by:
- **Safety**: Type-safe communication between Rust and TypeScript
- **Reliability**: Clear separation of concerns and dependency management
- **Performance**: Rust core for heavy operations, efficient build system
