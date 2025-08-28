# PRRTT Stack Analysis

This document provides a detailed analysis of how the PRRTT stack (Prisma, Rust, React, TypeScript, Tauri) is implemented in Overdrive, including data flow, communication patterns, and integration points.

## Overview

The PRRTT stack enables a unique architecture where:
- **Prisma** manages database schema and generates type-safe Rust client code
- **Rust** provides the core backend logic with memory safety and performance
- **React** delivers the user interface with component-based architecture
- **TypeScript** ensures type safety across the frontend
- **Tauri** bridges the Rust backend and web frontend in a native desktop app

## 1. Prisma Integration

### Schema Definition (`core/prisma/schema.prisma`)

```prisma
datasource db {
  provider = "sqlite"
  url      = "file:dev.db"
}

generator client {
  provider      = "cargo prisma"
  output        = "../../crates/prisma/src/prisma"
  module_path   = "prisma"
  client_format = "folder"
}

generator sync {
  provider      = "cargo prisma-sync"
  output        = "../../crates/prisma/src/prisma_sync"
  client_format = "folder"
}
```

### Custom Rust Generators

**Prisma Client Generator** (`crates/prisma-cli/src/bin/prisma.rs`):
```rust
fn main() {
    prisma_client_rust_generator::run();
}
```

**Generated Client Usage** (`crates/prisma/src/lib.rs`):
```rust
pub mod prisma;
pub mod prisma_sync;

pub async fn test_db() -> std::sync::Arc<prisma::PrismaClient> {
    prisma::PrismaClient::_builder()
        .build()
        .await
        .unwrap()
        .into()
}
```

### Database Models

Key models in the schema:
- **File Management**: `file_path`, `object`, `location`
- **Media Processing**: `ffmpeg_data`, `exif_data`
- **Organization**: `album`, `tag`, `label`
- **Sync**: `crdt_operation`, `cloud_crdt_operation`
- **System**: `device`, `instance`, `job`

### Type Safety Benefits

1. **Compile-time Validation**: Database queries are validated at compile time
2. **Auto-generated Types**: Rust structs match database schema exactly
3. **Migration Safety**: Schema changes require code updates
4. **Query Builder**: Type-safe query construction

## 2. Rust Core Architecture

### Core Library Structure (`core/src/`)

```rust
// Main library entry point
pub mod api;          // RPC API definitions
pub mod cloud;        // Cloud synchronization
pub mod job;          // Background job system
pub mod library;      // Library management
pub mod location;     // File location handling
pub mod node;         // Core node functionality
pub mod object;       // File object management
pub mod p2p;          // Peer-to-peer networking
pub mod sync;         // Data synchronization
pub mod util;         // Utility functions
pub mod volume;       // Storage volume management
```

### API Layer (`core/src/api/`)

The API layer exposes Rust functionality to the frontend via rspc:

```rust
// Example API router definition
pub fn mount() -> AlphaRouter<Ctx> {
    <AlphaRouter<Ctx>>::new()
        .procedure("version", R.query(|_, _: ()| env!("CARGO_PKG_VERSION")))
        .procedure("buildInfo", R.query(|_, _: ()| {
            BuildInfo {
                version: env!("CARGO_PKG_VERSION").to_string(),
                commit: env!("GIT_HASH").to_string(),
            }
        }))
        .merge("files.", files::mount())
        .merge("library.", library::mount())
        .merge("locations.", locations::mount())
}
```

### Core Services

**File Indexer** (`core/crates/heavy-lifting/`):
- Scans directories for files
- Extracts metadata
- Generates thumbnails
- Updates database

**Sync Engine** (`core/crates/sync/`):
- CRDT-based synchronization
- Conflict resolution
- Multi-device consistency

**Job System** (`core/src/job/`):
- Background task processing
- Progress tracking
- Error handling

## 3. React Frontend Architecture

### Component Structure (`interface/app/`)

```
interface/app/
├── $libraryId/           # Library-specific routes
│   ├── Explorer/         # File explorer components
│   ├── Search/           # Search functionality
│   ├── Settings/         # Application settings
│   └── overview/         # Library overview
├── onboarding/           # First-time setup
└── p2p/                  # P2P networking UI
```

### Key Components

**Explorer Component** (`interface/app/$libraryId/Explorer/`):
```typescript
export const Explorer = () => {
  const { library } = useLibraryContext();
  const explorer = useExplorer();

  return (
    <div className="flex h-full">
      <Sidebar />
      <div className="flex-1">
        <TopBar />
        <View />
      </div>
    </div>
  );
};
```

**File Operations** (`interface/app/$libraryId/Explorer/File/`):
- File preview
- Context menus
- Drag and drop
- Bulk operations

### State Management

**React Query Integration**:
```typescript
// Using rspc with React Query
const files = rspc.useQuery(['files.list', { locationId }]);
const createFile = rspc.useMutation('files.create');
```

**Context Providers**:
- `LibraryContextProvider` - Current library state
- `ExplorerContextProvider` - File explorer state
- `P2PContextProvider` - Networking state

## 4. TypeScript Integration

### Type Generation

**rspc Type Generation** (`apps/desktop/src-tauri/src/main.rs`):
```rust
#[cfg(debug_assertions)]
fn export_types() {
    use specta_typescript::Typescript;

    let config = Typescript::default();
    tauri_specta::ts::export_with_cfg(
        invoke_handler(),
        "../src/bindings.ts",
        config,
    ).unwrap();
}
```

### Generated Types (`packages/client/src/`)

**RPC Client Types**:
```typescript
// Auto-generated from Rust API
export type BuildInfo = {
  version: string;
  commit: string;
};

export type FileObject = {
  id: number;
  name: string;
  size: bigint;
  date_created: string;
  // ... more fields
};
```

### Type-Safe RPC Calls

**Client Usage** (`interface/hooks/`):
```typescript
import { rspc } from '@sd/client';

export function useFiles(locationId: number) {
  return rspc.useQuery(['files.list', { locationId }], {
    enabled: locationId !== null,
  });
}

export function useCreateFile() {
  return rspc.useMutation('files.create', {
    onSuccess: () => {
      // Invalidate and refetch
      rspc.queryClient.invalidateQueries(['files.list']);
    },
  });
}
```

## 5. Tauri Integration

### Tauri Configuration (`apps/desktop/src-tauri/tauri.conf.json`)

```json
{
  "build": {
    "beforeDevCommand": "pnpm dev",
    "beforeBuildCommand": "pnpm build",
    "devPath": "http://localhost:1420",
    "distDir": "../dist"
  },
  "tauri": {
    "allowlist": {
      "all": false,
      "shell": {
        "all": false,
        "open": true
      },
      "dialog": {
        "all": false,
        "open": true,
        "save": true
      }
    }
  }
}
```

### Rust Backend (`apps/desktop/src-tauri/src/main.rs`)

```rust
use sd_core::Node;
use tauri::Manager;

#[tauri::command]
async fn app_ready(app_handle: tauri::AppHandle) {
    let window = app_handle.get_window("main").unwrap();
    window.show().unwrap();
}

fn main() {
    let (node, router) = Node::new().await;

    tauri::Builder::default()
        .plugin(rspc::integrations::tauri::plugin(router, || ()))
        .invoke_handler(tauri::generate_handler![app_ready])
        .setup(|app| {
            let window = app.get_window("main").unwrap();
            window.hide().unwrap(); // Hide until ready
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

### Frontend Integration (`apps/desktop/src/App.tsx`)

```typescript
import { rspc, queryClient } from '@sd/client';
import { QueryClientProvider } from '@tanstack/react-query';

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <rspc.Provider client={client}>
        <Router />
      </rspc.Provider>
    </QueryClientProvider>
  );
}
```

## Data Flow Analysis

### 1. File Operation Flow

```
User clicks "Open Folder" (React)
    ↓
TypeScript event handler calls rspc
    ↓
rspc serializes request to Tauri
    ↓
Tauri invokes Rust command
    ↓
Rust core processes file operation
    ↓
Prisma client updates database
    ↓
Response flows back through layers
    ↓
React component re-renders with new data
```

### 2. Real-time Updates

```
File system watcher (Rust)
    ↓
Core emits change event
    ↓
rspc subscription notifies frontend
    ↓
React Query invalidates cache
    ↓
Components automatically re-render
```

### 3. Background Jobs

```
User initiates scan (React)
    ↓
Job queued in Rust core
    ↓
Background worker processes job
    ↓
Progress updates via rspc subscription
    ↓
UI shows real-time progress
```

## Performance Characteristics

### 1. Memory Usage
- **Rust Core**: Minimal memory footprint, no garbage collection
- **React Frontend**: Standard React memory usage
- **Tauri**: Lower than Electron due to system webview

### 2. CPU Usage
- **Heavy Operations**: Handled in Rust with optimal performance
- **UI Rendering**: Standard web performance in system webview
- **Background Tasks**: Efficient async processing in Rust

### 3. I/O Performance
- **Database**: SQLite with optimized queries
- **File Operations**: Direct system calls from Rust
- **Network**: Async I/O with tokio

## Security Model

### 1. Tauri Security
- **Allowlist**: Restricted API access
- **CSP**: Content Security Policy enforcement
- **IPC**: Secure inter-process communication

### 2. Type Safety
- **Compile-time Checks**: Rust prevents memory safety issues
- **Runtime Validation**: TypeScript catches type errors
- **API Contracts**: rspc ensures consistent interfaces

### 3. Data Protection
- **Local Storage**: SQLite database with file system permissions
- **Encryption**: Crypto operations in Rust
- **Sandboxing**: Tauri security model

## Overdrive Optimizations

### 1. Simplifications for Linux/Android
- Remove platform-specific Tauri features
- Optimize for GTK/WebKit on Linux
- Prepare for Android WebView integration

### 2. Performance Improvements
- Reduce TypeScript bundle size
- Optimize Rust compilation for target platforms
- Streamline database schema for core features

### 3. Development Experience
- Faster hot reload with focused scope
- Simplified build process
- Better error messages for Linux-specific issues

This PRRTT stack analysis demonstrates how Overdrive achieves:
- **Safety**: Type safety across the entire stack
- **Reliability**: Consistent data flow and error handling
- **Performance**: Optimal performance through Rust core with web UI flexibility
