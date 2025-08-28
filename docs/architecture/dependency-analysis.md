# Overdrive Dependency Analysis

This document analyzes the dependency relationships within the Overdrive monorepo, identifying critical paths, potential simplifications, and areas for optimization.

## Cargo Workspace Dependencies

### Core Dependencies (`core/Cargo.toml`)

#### Essential Runtime Dependencies
```toml
# Database and ORM
prisma-client-rust = { workspace = true, features = ["rspc"] }

# Async runtime and utilities
tokio = { workspace = true, features = ["io-util", "macros", "process", "rt-multi-thread", "sync", "time"] }
futures = { workspace = true }
async-stream = { workspace = true }

# RPC and API
rspc = { workspace = true, features = ["alpha", "axum", "chrono", "unstable", "uuid"] }
axum = { workspace = true, features = ["ws"] }

# Serialization
serde = { workspace = true, features = ["derive", "rc"] }
serde_json = { workspace = true }
rmp-serde = { workspace = true }

# Cryptography and hashing
blake3 = { workspace = true }
uuid = { workspace = true, features = ["serde", "v4", "v7"] }

# File system operations
normpath = { workspace = true, features = ["localization"] }
globset = { workspace = true }
```

#### Internal Crate Dependencies
```toml
# Core sub-crates
sd-core-cloud-services = { path = "./crates/cloud-services" }
sd-core-file-path-helper = { path = "./crates/file-path-helper" }
sd-core-heavy-lifting = { path = "./crates/heavy-lifting" }
sd-core-indexer-rules = { path = "./crates/indexer-rules" }
sd-core-prisma-helpers = { path = "./crates/prisma-helpers" }
sd-core-sync = { path = "./crates/sync" }

# Shared crates
sd-actors = { path = "../crates/actors" }
sd-crypto = { path = "../crates/crypto" }
sd-file-ext = { path = "../crates/file-ext" }
sd-images = { path = "../crates/images", features = ["rspc", "serde", "specta"] }
sd-media-metadata = { path = "../crates/media-metadata" }
sd-prisma = { path = "../crates/prisma" }
sd-sync = { path = "../crates/sync" }
sd-task-system = { path = "../crates/task-system" }
sd-utils = { path = "../crates/utils" }
```

### Desktop App Dependencies (`apps/desktop/src-tauri/Cargo.toml`)

#### Tauri Framework
```toml
tauri = { version = "=2.0.6", features = ["linux-libxdo", "macos-private-api", "native-tls-vendored", "unstable"] }
tauri-specta = { git = "https://github.com/spacedriveapp/tauri-specta", rev = "8c85d40eb9", features = ["derive", "typescript"] }

# Tauri plugins
tauri-plugin-clipboard-manager = "=2.0.1"
tauri-plugin-deep-link = "=2.0.1"
tauri-plugin-dialog = "=2.0.3"
tauri-plugin-drag = "2.0.0"
tauri-plugin-http = "=2.0.3"
tauri-plugin-os = "=2.0.1"
tauri-plugin-shell = "=2.0.2"
tauri-plugin-updater = "=2.0.2"
```

#### Core Integration
```toml
sd-core = { path = "../../../core", features = ["ffmpeg", "heif"] }
sd-fda = { path = "../../../crates/fda" }
sd-prisma = { path = "../../../crates/prisma" }
```

## pnpm Workspace Dependencies

### Root Package Dependencies (`package.json`)

#### Build Tools
```json
{
  "devDependencies": {
    "prisma": "^5.18.0",
    "turbo": "^1.12.5",
    "typescript": "^5.6.2",
    "prettier": "^3.3.3",
    "vite": "^5.4.9"
  }
}
```

### Desktop App Frontend (`apps/desktop/package.json`)

#### Core Frontend Dependencies
```json
{
  "dependencies": {
    "@sd/client": "workspace:*",
    "@sd/interface": "workspace:*",
    "@sd/ui": "workspace:*",

    "@spacedrive/rspc-client": "github:spacedriveapp/rspc#path:packages/client&6a77167495",
    "@spacedrive/rspc-tauri": "github:spacedriveapp/rspc#path:packages/tauri&6a77167495",

    "@tauri-apps/api": "=2.0.3",
    "@tauri-apps/plugin-dialog": "2.0.1",
    "@tauri-apps/plugin-http": "2.0.1",
    "@tauri-apps/plugin-os": "2.0.0",
    "@tauri-apps/plugin-shell": "2.0.1",

    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "=6.20.1"
  }
}
```

### Interface Package (`interface/package.json`)

#### UI Framework Dependencies
```json
{
  "dependencies": {
    "@sd/client": "workspace:*",
    "@sd/ui": "workspace:*",
    "@sd/assets": "workspace:*",

    "react": "^18.2.0",
    "react-router-dom": "=6.20.1",
    "@tanstack/react-query": "^5.59"
  }
}
```

## Critical Dependency Paths

### 1. Database Layer
```
SQLite Database
    ↑
Prisma Schema (core/prisma/schema.prisma)
    ↑
Generated Prisma Client (crates/prisma/src/prisma/)
    ↑
Core Database Operations (core/src/)
    ↑
Desktop App Backend (apps/desktop/src-tauri/)
```

### 2. RPC Communication
```
React Components (interface/)
    ↓ (rspc calls)
TypeScript Client (packages/client/)
    ↓ (HTTP/WebSocket)
Tauri Backend (apps/desktop/src-tauri/)
    ↓ (rspc handlers)
Core API (core/src/api/)
    ↓ (business logic)
Core Services (core/src/)
```

### 3. File System Operations
```
User File Operations (interface/)
    ↓
File System API (core/src/api/files.rs)
    ↓
File Path Helper (core/crates/file-path-helper/)
    ↓
Heavy Lifting (core/crates/heavy-lifting/)
    ↓
System File APIs
```

## Dependency Categories

### 1. Essential Dependencies (Cannot Remove)
- **Rust Core**: tokio, serde, prisma-client-rust
- **Tauri Framework**: tauri, tauri plugins
- **React Framework**: react, react-dom
- **RPC**: rspc (custom fork)
- **Database**: SQLite, Prisma

### 2. Feature Dependencies (Optional)
- **Media Processing**: ffmpeg, image processing
- **AI Features**: sd-ai crate
- **Cloud Services**: cloud integration crates

### 3. Development Dependencies
- **Build Tools**: turbo, vite, typescript
- **Code Quality**: eslint, prettier
- **Testing**: Various test frameworks

### 4. Platform Dependencies (Linux Focus)
- **Linux System**: GTK, WebKit2GTK, GStreamer
- **Build Tools**: clang, nasm, pkg-config

## Overdrive Simplification Opportunities

### Dependencies to Remove
1. **Platform-Specific**: macOS/Windows/iOS dependencies
2. **Web App**: Next.js, web-specific packages
3. **React Native**: Mobile app dependencies
4. **Cloud Services**: Third-party integrations (initially)
5. **Landing Page**: Marketing site dependencies

### Dependencies to Simplify
1. **UI Framework**: Reduce React complexity, fewer external UI libraries
2. **Build System**: Focus on Linux-only builds
3. **Storybook**: Minimal component documentation
4. **Internationalization**: Start with English only

### Dependencies to Retain
1. **Core Rust**: All essential crates
2. **Tauri**: Desktop and future Android support
3. **Database**: Prisma + SQLite
4. **RPC**: rspc for type-safe communication
5. **File Processing**: Image, media metadata

## Dependency Risks and Mitigations

### 1. Custom Forks Risk
- **rspc**: Custom fork for Spacedrive-specific features
- **prisma-client-rust**: Custom fork for Rust integration
- **Mitigation**: Document fork differences, consider upstreaming changes

### 2. Version Lock Risk
- **Tauri**: Locked to specific version (2.0.6)
- **React Router**: Locked to specific version (6.20.1)
- **Mitigation**: Regular updates, compatibility testing

### 3. Platform Dependency Risk
- **Linux Libraries**: GTK, WebKit dependencies
- **Mitigation**: Support multiple package managers, clear documentation

### 4. Build Complexity Risk
- **Multiple Build Systems**: Cargo + pnpm + Tauri
- **Mitigation**: Automated scripts, clear build documentation

## Optimization Recommendations

### 1. Dependency Consolidation
- Reduce number of external UI libraries
- Consolidate similar functionality into fewer crates
- Remove unused features from workspace dependencies

### 2. Build Optimization
- Use cargo features to make dependencies optional
- Implement conditional compilation for Linux-only code
- Optimize build profiles for development vs. production

### 3. Version Management
- Establish clear update policy for locked versions
- Regular security audits of dependencies
- Automated dependency update testing

### 4. Documentation
- Maintain clear dependency rationale documentation
- Document all custom forks and modifications
- Create dependency update procedures

This analysis supports Overdrive's goals by:
- **Safety**: Identifying critical dependencies that need careful management
- **Reliability**: Understanding dependency risks and mitigation strategies
- **Performance**: Highlighting optimization opportunities for faster builds
