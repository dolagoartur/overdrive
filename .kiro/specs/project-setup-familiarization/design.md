# Design Document

## Overview

This design document outlines the approach for Phase 1 of the Overdrive project: Project Setup and Familiarization. The goal is to establish a solid foundation for transforming Spacedrive into a Linux/Android-focused file manager while understanding the existing architecture and identifying components for retention or removal.

The design focuses on creating a systematic approach to environment setup, codebase analysis, and scope definition that will enable efficient development in subsequent phases.

## Architecture

### Current Spacedrive Architecture Analysis

Based on the codebase examination, Spacedrive uses the "PRRTT" stack:

- **Prisma**: Database ORM with Rust client for type-safe database operations
- **Rust**: Core backend logic in `sdcore` with additional crates for specialized functionality
- **React**: Frontend UI framework with TypeScript
- **TypeScript**: Type-safe JavaScript for frontend development
- **Tauri**: Cross-platform desktop app framework using system webview

### Key Components Identified

#### Core Components to Retain
- `core/`: The main Rust core (`sdcore`) containing filesystem, database, and networking logic
- `crates/`: Shared Rust libraries (crypto, file-ext, images, media-metadata, etc.)
- `apps/desktop/`: Tauri-based desktop application
- `interface/`: React-based UI components
- `packages/client/`: TypeScript client library for RPC communication
- `packages/ui/`: Shared React component library

#### Components to Remove/Simplify
- `apps/landing/`: Next.js landing page (not needed for Overdrive)
- `apps/storybook/`: Component documentation (can be simplified)
- `apps/web/`: Separate web app (focus on desktop/mobile only)
- `apps/server/`: Standalone server (desktop app has embedded backend)
- Platform-specific native binaries for macOS/Windows/iOS
- React Native mobile app (will use Tauri for Android instead)

### Development Environment Requirements

#### System Dependencies
- **Rust**: Version 1.81 (specified in rust-toolchain.toml)
- **Node.js**: Version 18.18+ (specified in .nvmrc)
- **pnpm**: Version 9.4.0+ for package management
- **System packages**: Platform-specific dependencies via setup scripts

#### Build System Analysis
- **Cargo workspace**: Manages Rust crates and dependencies
- **pnpm workspace**: Manages Node.js packages and monorepo structure
- **Turbo**: Build system for efficient monorepo builds
- **Tauri CLI**: Desktop app development and building

## Components and Interfaces

### Environment Setup Component

**Purpose**: Automate the setup of development dependencies and build tools

**Interface**:
```bash
# Unix systems
./scripts/setup.sh

# Windows systems
.\scripts\setup.ps1
```

**Responsibilities**:
- Verify Rust toolchain installation and version
- Verify Node.js and pnpm installation
- Install system-specific dependencies
- Configure development environment

### Build System Component

**Purpose**: Provide consistent build commands across the monorepo

**Interface**:
```bash
# Install dependencies
pnpm i

# Prepare build (codegen, prisma)
pnpm prep

# Development mode
pnpm tauri dev

# Production build
pnpm build
```

**Responsibilities**:
- Manage dependency installation
- Handle code generation (Prisma, rspc bindings)
- Coordinate Rust and TypeScript builds
- Provide development server with hot reload

### Codebase Analysis Component

**Purpose**: Systematic examination of the existing codebase structure

**Interface**: Manual analysis with documentation output

**Responsibilities**:
- Map monorepo structure and dependencies
- Identify platform-specific code sections
- Document RPC communication patterns
- Catalog existing features and functionality

### Scope Definition Component

**Purpose**: Define clear boundaries for Overdrive development

**Interface**: Documentation and configuration updates

**Responsibilities**:
- Document Linux/Android-only focus
- Define MVP feature set
- Establish development priorities
- Create removal plan for unused components

## Data Models

### Project Structure Model

```
overdrive/
├── core/                    # Rust core (retain)
├── crates/                  # Shared Rust libraries (retain)
├── apps/
│   ├── desktop/            # Tauri desktop app (retain, modify)
│   ├── mobile/             # React Native (remove, replace with Tauri)
│   ├── web/                # Web app (remove)
│   ├── landing/            # Landing page (remove)
│   ├── server/             # Standalone server (remove)
│   └── storybook/          # Component docs (simplify)
├── interface/              # React UI (retain, simplify)
├── packages/
│   ├── client/             # RPC client (retain)
│   ├── ui/                 # Component library (retain, simplify)
│   ├── config/             # Build configs (retain, modify)
│   └── assets/             # Shared assets (retain)
└── [platform-specific]/   # Remove macOS/Windows/iOS specific
```

### Dependency Analysis Model

```rust
// Core dependencies to understand
sd-core = { path = "../../../core", features = ["ffmpeg", "heif"] }
rspc = { workspace = true, features = ["tauri"] }
prisma-client-rust = { workspace = true }
tauri = { version = "=2.0.6", features = ["linux-libxdo"] }
```

### Feature Scope Model

```yaml
MVP Features:
  - File indexing/discovery
  - Basic file explorer UI
  - File metadata display
  - Basic file operations (open, rename, delete)

Future Features:
  - Android support via Tauri
  - Multi-device sync
  - Advanced search
  - Thumbnail generation
```

## Error Handling

### Build Error Recovery

**Common Issues**:
- Missing system dependencies
- Version mismatches (Rust, Node.js, pnpm)
- Platform-specific build failures
- Database migration issues

**Recovery Strategies**:
- Automated dependency checking in setup scripts
- Clear error messages with resolution steps
- Fallback build configurations
- Clean build commands (`pnpm clean`)

### Development Environment Issues

**Common Issues**:
- IDE configuration problems
- Hot reload failures
- RPC binding generation errors
- Database connection issues

**Recovery Strategies**:
- Standardized IDE configuration files
- Development server restart procedures
- Codegen regeneration commands
- Database reset procedures

## Testing Strategy

### Environment Validation Testing

**Approach**: Automated verification of development environment setup

**Test Cases**:
- Verify all required tools are installed and correct versions
- Test basic build commands execute successfully
- Validate desktop app launches without errors
- Confirm hot reload functionality works

**Implementation**:
```bash
# Test script to validate environment
./scripts/validate-environment.sh
```

### Codebase Understanding Validation

**Approach**: Manual verification of architecture comprehension

**Test Cases**:
- Successfully explain PRRTT stack interactions
- Identify key RPC endpoints and their purposes
- Map data flow from UI to Rust core
- Locate and understand database schema

**Implementation**: Documentation review and peer validation

### Build System Testing

**Approach**: Verify all build configurations work correctly

**Test Cases**:
- Clean build from scratch succeeds
- Development mode with hot reload functions
- Production build generates correct artifacts
- Cross-compilation for target platforms works

**Implementation**:
```bash
# Test build pipeline
pnpm clean
pnpm i
pnpm prep
pnpm build
```

### Scope Definition Validation

**Approach**: Ensure MVP goals are realistic and achievable

**Test Cases**:
- MVP features are clearly defined and measurable
- Removed components don't break core functionality
- Linux/Android focus is technically feasible
- Development timeline is realistic

**Implementation**: Technical feasibility analysis and documentation review

## Implementation Notes

### Phase 1 Success Criteria

1. **Environment Setup Complete**: Developer can build and run Spacedrive on Linux
2. **Architecture Understood**: Clear documentation of PRRTT stack and component interactions
3. **Scope Defined**: Written plan for what to keep/remove/modify for Overdrive
4. **MVP Planned**: Specific, measurable goals for minimal viable product
5. **Development Workflow**: Efficient setup for subsequent development phases

### Key Deliverables

1. **Working Development Environment**: All tools installed and configured
2. **Architecture Documentation**: Written analysis of Spacedrive's design
3. **Component Audit**: Detailed list of what to retain/remove/modify
4. **MVP Specification**: Clear definition of initial Overdrive features
5. **Development Setup Guide**: Instructions for other contributors

### Risk Mitigation

- **Complexity Risk**: Focus on understanding core components first, defer advanced features
- **Platform Risk**: Validate Linux build works before planning Android support
- **Scope Risk**: Keep MVP minimal and achievable for first-time open source contribution
- **Technical Risk**: Use AI assistant for complex Rust/TypeScript concepts

This design provides a structured approach to Phase 1 that balances thorough understanding with practical progress toward the Overdrive goals.
