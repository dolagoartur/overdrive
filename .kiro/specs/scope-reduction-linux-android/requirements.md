# Requirements Document - Scope Reduction to Linux and Android

## Introduction

This phase focuses on completing the reduction of Overdrive's scope to Linux desktop and Android mobile platforms only. Several applications have already been removed (storybook, landing, web), and this phase will complete the removal of remaining unused components (mobile app, server), platform-specific code (Windows, macOS, iOS), and associated dependencies. The goal is to simplify the codebase, reduce build complexity, and improve development velocity while preserving all essential functionality for the target platforms.

## Requirements

### Requirement 1: Complete Application Removal

**User Story:** As a developer working on Overdrive, I want remaining unused applications removed so that the codebase is focused and maintainable.

#### Acceptance Criteria

1. WHEN removing mobile app THEN the entire `apps/mobile/` directory SHALL be deleted
2. WHEN removing server references THEN all server-related scripts SHALL be removed from package.json
3. WHEN applications are removed THEN the desktop app SHALL still build and run successfully
4. WHEN applications are removed THEN no broken references SHALL remain in configuration files
5. WHEN workspace is updated THEN only desktop app SHALL be included in workspace members
6. WHEN cleanup is complete THEN build time SHALL be measurably reduced

### Requirement 2: Remove Platform-Specific Code

**User Story:** As a developer, I want platform-specific code for unsupported platforms removed so that the codebase is clean and focused.

#### Acceptance Criteria

1. WHEN removing Windows code THEN all `#[cfg(windows)]` blocks SHALL be removed
2. WHEN removing macOS code THEN all `#[cfg(target_os = "macos")]` blocks SHALL be removed
3. WHEN removing iOS code THEN all `#[cfg(target_os = "ios")]` blocks SHALL be removed
4. WHEN platform code is removed THEN Linux functionality SHALL remain intact
5. WHEN platform code is removed THEN Android preparation code SHALL be preserved
6. WHEN conditional compilation is cleaned THEN no unused imports SHALL remain

### Requirement 3: Clean Up Dependencies

**User Story:** As a developer, I want unused dependencies removed so that builds are faster and the dependency tree is simpler.

#### Acceptance Criteria

1. WHEN removing Windows dependencies THEN all Windows-specific Cargo dependencies SHALL be removed
2. WHEN removing macOS dependencies THEN all macOS-specific Cargo dependencies SHALL be removed
3. WHEN removing iOS dependencies THEN all iOS-specific Cargo dependencies SHALL be removed
4. WHEN removing app dependencies THEN unused Node.js packages SHALL be removed
5. WHEN dependencies are cleaned THEN the desktop app SHALL still build successfully
6. WHEN dependencies are cleaned THEN build time SHALL be reduced by at least 20%

### Requirement 4: Update Build System

**User Story:** As a developer, I want the build system optimized for Linux/Android only so that builds are faster and simpler.

#### Acceptance Criteria

1. WHEN updating Cargo workspace THEN removed apps SHALL not be included in workspace members
2. WHEN updating package.json THEN removed apps SHALL not be referenced in scripts
3. WHEN updating Tauri config THEN only Linux build targets SHALL be included
4. WHEN updating build system THEN all build commands SHALL work correctly
5. WHEN build system is updated THEN CI/CD pipeline SHALL be simplified for Linux-only

### Requirement 5: Preserve Essential Functionality

**User Story:** As a user, I want all desktop functionality preserved so that the application works exactly as before.

#### Acceptance Criteria

1. WHEN scope is reduced THEN all desktop file management features SHALL work
2. WHEN scope is reduced THEN the desktop app SHALL launch successfully
3. WHEN scope is reduced THEN all existing user data SHALL remain accessible
4. WHEN scope is reduced THEN performance SHALL be maintained or improved
5. WHEN scope is reduced THEN no regressions SHALL be introduced

### Requirement 6: Update Documentation

**User Story:** As a contributor, I want documentation updated to reflect the new scope so that setup and development are clear.

#### Acceptance Criteria

1. WHEN scope is reduced THEN README SHALL be updated with new project focus
2. WHEN scope is reduced THEN setup instructions SHALL be Linux/Android focused
3. WHEN scope is reduced THEN build documentation SHALL reflect removed components
4. WHEN scope is reduced THEN contributor guides SHALL be updated
5. WHEN documentation is updated THEN new contributors SHALL be able to set up development environment

### Requirement 7: Validate Changes

**User Story:** As a developer, I want comprehensive validation that changes work correctly so that no functionality is broken.

#### Acceptance Criteria

1. WHEN changes are complete THEN desktop app SHALL build from clean environment
2. WHEN changes are complete THEN desktop app SHALL run without errors
3. WHEN changes are complete THEN all core features SHALL be tested
4. WHEN changes are complete THEN performance benchmarks SHALL be met or improved
5. WHEN changes are complete THEN automated tests SHALL pass

### Requirement 8: Measure Improvements

**User Story:** As a project maintainer, I want to measure the improvements from scope reduction so that the benefits are quantified.

#### Acceptance Criteria

1. WHEN scope reduction is complete THEN build time improvement SHALL be measured
2. WHEN scope reduction is complete THEN codebase size reduction SHALL be measured
3. WHEN scope reduction is complete THEN dependency count reduction SHALL be measured
4. WHEN scope reduction is complete THEN disk usage reduction SHALL be measured
5. WHEN measurements are complete THEN results SHALL be documented for future reference
