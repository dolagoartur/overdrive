# Implementation Plan - Scope Reduction to Linux and Android

- [x] 1. Prepare for safe removal
  - Create backup branch and validation baseline
  - Set up automated testing pipeline for validation
  - Document current build metrics for comparison
  - _Requirements: 7.1, 8.1_

- [ ] 2. Remove unused applications
  - [x] 2.1 Remove Storybook application
    - Delete `apps/storybook/` directory completely
    - Remove storybook references from root package.json scripts
    - Update workspace configuration to exclude storybook
    - Validate desktop app still builds and runs
    - _Requirements: 1.1, 1.6, 1.7_

  - [x] 2.2 Remove landing page application
    - Delete `apps/landing/` directory completely
    - Remove landing references from root package.json scripts
    - Remove landing-web combined script from package.json
    - Update workspace configuration to exclude landing
    - Validate desktop app still builds and runs
    - _Requirements: 1.1, 1.6, 1.7_

  - [x] 2.3 Remove web application
    - Delete `apps/web/` directory completely
    - Remove web references from root package.json scripts
    - Remove dev:web and web-related scripts from package.json
    - Update workspace configuration to exclude web
    - Validate desktop app still builds and runs
    - _Requirements: 1.1, 1.6, 1.7_

  - [ ] 2.4 Remove server application
    - Delete `apps/server/` directory completely
    - Remove server references from root package.json scripts
    - Update Cargo.toml workspace members to exclude server
    - Validate desktop app still builds and runs
    - _Requirements: 1.1, 1.6, 1.7_

  - [ ] 2.5 Remove mobile application
    - Delete `apps/mobile/` directory completely
    - Remove mobile references from root package.json scripts
    - Update Cargo.toml workspace members to exclude mobile crates
    - Remove React Native and Expo related dependencies
    - Validate desktop app still builds and runs
    - _Requirements: 1.1, 1.6, 1.7_

- [ ] 3. Remove platform-specific code
  - [ ] 3.1 Remove Windows-specific code
    - Remove all `#[cfg(windows)]` conditional compilation blocks
    - Remove Windows-specific imports and modules
    - Delete `core/src/volume/windows.rs` if it exists
    - Remove Windows-specific dependencies from Cargo.toml
    - Clean up unused imports after Windows code removal
    - _Requirements: 2.1, 2.4, 2.6_

  - [ ] 3.2 Remove macOS-specific code
    - Remove all `#[cfg(target_os = "macos")]` conditional compilation blocks
    - Remove macOS-specific imports and modules
    - Delete `core/src/volume/macos.rs` and `crates/utils/src/macos.rs`
    - Remove macOS-specific dependencies (cocoa, objc) from Cargo.toml
    - Clean up unused imports after macOS code removal
    - _Requirements: 2.2, 2.4, 2.6_

  - [ ] 3.3 Remove iOS-specific code
    - Remove all `#[cfg(target_os = "ios")]` conditional compilation blocks
    - Remove iOS-specific imports and modules
    - Remove iOS-specific dependencies (swift-rs) from Cargo.toml
    - Remove iOS mobile crate references from workspace
    - Clean up unused imports after iOS code removal
    - _Requirements: 2.3, 2.4, 2.6_

  - [ ] 3.4 Preserve Linux and Android code
    - Verify Linux-specific code remains intact
    - Preserve Android-specific dependencies for future use
    - Update volume management to use Linux implementation by default
    - Ensure Android preparation code is maintained
    - Test that Linux functionality works correctly
    - _Requirements: 2.4, 2.5, 5.1, 5.2_

- [ ] 4. Clean up dependencies
  - [ ] 4.1 Remove platform-specific Cargo dependencies
    - Remove Windows workspace dependencies from root Cargo.toml
    - Remove macOS dependencies from desktop app Cargo.toml
    - Remove iOS dependencies from root Cargo.toml
    - Keep Android dependencies for future Tauri mobile support
    - Update dependency versions and clean up unused features
    - _Requirements: 3.1, 3.2, 3.3, 3.5_

  - [ ] 4.2 Clean up Node.js package dependencies
    - Remove dependencies unique to deleted applications
    - Update shared package dependencies to remove unused packages
    - Clean up pnpm patches for removed applications
    - Update package.json overrides to remove unused packages
    - Verify all retained packages still have required dependencies
    - _Requirements: 3.4, 3.5, 3.6_

  - [ ] 4.3 Update workspace configurations
    - Update root package.json to remove references to deleted apps
    - Update pnpm workspace configuration
    - Update Turbo configuration to remove deleted app targets
    - Clean up any remaining references in configuration files
    - Verify workspace dependency resolution works correctly
    - _Requirements: 4.1, 4.2, 4.4_

- [ ] 5. Update build system
  - [ ] 5.1 Update Tauri configuration
    - Remove non-Linux build targets from tauri.conf.json
    - Keep only appimage and deb bundle targets
    - Remove platform-specific Tauri features and plugins
    - Update Tauri permissions for Linux-only operation
    - Test that Tauri builds work correctly for Linux
    - _Requirements: 4.3, 4.4, 5.1_

  - [ ] 5.2 Simplify build scripts
    - Update root package.json scripts to remove deleted apps
    - Keep essential scripts for desktop development
    - Update bootstrap and development scripts
    - Remove platform-specific build commands
    - Test that all remaining build scripts work correctly
    - _Requirements: 4.2, 4.4, 5.1_

  - [ ] 5.3 Update CI/CD configuration
    - Simplify GitHub Actions workflows for Linux-only builds
    - Remove platform-specific build jobs
    - Update test matrix to focus on Linux distributions
    - Optimize build pipeline for faster execution
    - Test that CI/CD pipeline works with changes
    - _Requirements: 4.5, 5.1_

- [ ] 6. Update documentation
  - [ ] 6.1 Update project documentation
    - Update README.md to reflect Linux/Android focus
    - Update project description and goals
    - Remove references to removed platforms and applications
    - Update installation and setup instructions for Linux focus
    - Create migration guide for existing contributors
    - _Requirements: 6.1, 6.2, 6.4, 6.5_

  - [ ] 6.2 Update development documentation
    - Update CONTRIBUTING.md for new project scope
    - Update build and development instructions
    - Document new simplified workflow
    - Update troubleshooting guides
    - Remove outdated platform-specific documentation
    - _Requirements: 6.3, 6.4, 6.5_

- [ ] 7. Comprehensive validation
  - [ ] 7.1 Build system validation
    - Test clean environment setup using setup scripts
    - Verify desktop app builds successfully from scratch
    - Test development workflow with hot reload
    - Validate all build commands work correctly
    - Ensure no broken references or missing dependencies
    - _Requirements: 7.1, 7.2, 5.1, 5.2_

  - [ ] 7.2 Functionality validation
    - Test desktop app launches without errors
    - Verify all core file management features work
    - Test file operations (create, read, update, delete)
    - Verify database operations and migrations work
    - Test settings and configuration persistence
    - _Requirements: 7.3, 5.1, 5.2, 5.3_

  - [ ] 7.3 Performance validation
    - Measure and document build time improvements
    - Measure binary size reduction
    - Benchmark application startup time
    - Test memory usage and performance
    - Compare metrics against baseline measurements
    - _Requirements: 7.4, 8.1, 8.2, 8.3, 8.4_

- [ ] 8. Document improvements and finalize
  - [ ] 8.1 Measure and document improvements
    - Calculate build time reduction percentage
    - Measure codebase size reduction
    - Count dependency reduction
    - Document disk usage improvements
    - Create before/after comparison report
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

  - [ ] 8.2 Create migration documentation
    - Document what was removed and why
    - Create guide for contributors on new workflow
    - Document any breaking changes
    - Provide rollback instructions if needed
    - Update project roadmap to reflect completed phase
    - _Requirements: 6.5, 8.5_

  - [ ] 8.3 Final validation and cleanup
    - Run complete test suite to ensure no regressions
    - Perform final code review of all changes
    - Clean up any temporary files or scripts
    - Verify all documentation is accurate and complete
    - Prepare for Phase 3 by documenting lessons learned
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_
