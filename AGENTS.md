<div align="center">

# 🤖 MediaHub — AI Agent Instructions & Engineering Rules

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![State Management](https://img.shields.io/badge/State-Riverpod-00599C?style=for-the-badge)](https://riverpod.dev)
[![Database](https://img.shields.io/badge/Database-Drift_SQLite-003B5C?style=for-the-badge&logo=sqlite&logoColor=white)](https://drift.simonbinder.eu/)
[![Architecture](https://img.shields.io/badge/Architecture-Local--First-2E7D32?style=for-the-badge)](docs/ARCHITECTURE.md)
[![Agent Directive](https://img.shields.io/badge/Agent_Directive-Mandatory-D32F2F?style=for-the-badge)](AGENTS.md)

---

**This document defines the mandatory development rules, architecture constraints, coding standards, and step-by-step feature workflows that AI coding agents must strictly adhere to when working on MediaHub.**

</div>

---

> [!IMPORTANT]
> **MANDATORY FIRST STEP FOR AI AGENTS**: Before writing or modifying any code in this repository, you **MUST** read this file and the corresponding feature specification in `docs/`. The documentation inside `docs/` is the primary technical specification for the project.

---

## 📑 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Project Overview](#2-project-overview)
- [3. Core Product Concept](#3-core-product-concept)
- [4. Documentation Hierarchy](#4-documentation-hierarchy)
- [5. Documentation Is the Source of Truth](#5-documentation-is-the-source-of-truth)
- [6. MVP Boundary](#6-mvp-boundary)
- [7. Future Versions](#7-future-versions)
- [8. Development Philosophy](#8-development-philosophy)
- [9. Coding Principles](#9-coding-principles)
- [10. Flutter Rules](#10-flutter-rules)
- [11. State Management Rules](#11-state-management-rules)
- [12. Database Rules](#12-database-rules)
- [13. Media Library Rules](#13-media-library-rules)
- [14. Downloader Architecture](#14-downloader-architecture)
- [15. Downloader Safety Rules](#15-downloader-safety-rules)
- [16. Player Rules](#16-player-rules)
- [17. Music Player Rules](#17-music-player-rules)
- [18. Video Player Rules](#18-video-player-rules)
- [19. File-System Rules](#19-file-system-rules)
- [20. Media Scanner Rules](#20-media-scanner-rules)
- [21. Metadata Rules](#21-metadata-rules)
- [22. UI Rules](#22-ui-rules)
- [23. Navigation Rules](#23-navigation-rules)
- [24. Dependency Rules](#24-dependency-rules)
- [25. Security Rules](#25-security-rules)
- [26. Download Filename Rules](#26-download-filename-rules)
- [27. Error Handling](#27-error-handling)
- [28. User-Facing Errors](#28-user-facing-errors)
- [29. Offline Rules](#29-offline-rules)
- [30. Performance Rules](#30-performance-rules)
- [31. Media Artwork Rules](#31-media-artwork-rules)
- [32. Background Work](#32-background-work)
- [33. Database Migration Rules](#33-database-migration-rules)
- [34. Repository Rules](#34-repository-rules)
- [35. Service Rules](#35-service-rules)
- [36. Controller Rules](#36-controller-rules)
- [37. Testing Rules](#37-testing-rules)
- [38. Testability Rules](#38-testability-rules)
- [39. Git Rules](#39-git-rules)
- [40. Modification Rules](#40-modification-rules)
- [41. Refactoring Rules](#41-refactoring-rules)
- [42. Feature Implementation Workflow](#42-feature-implementation-workflow)
- [43. Roadmap Rules](#43-roadmap-rules)
- [44. Scope Control](#44-scope-control)
- [45. Cloud Architecture Rule](#45-cloud-architecture-rule)
- [46. Local Media Rule](#46-local-media-rule)
- [47. Downloader-to-Library Rule](#47-downloader-to-library-rule)
- [48. Player Independence Rule](#48-player-independence-rule)
- [49. UI State Rules](#49-ui-state-rules)
- [50. Empty State Rules](#50-empty-state-rules)
- [51. Accessibility Rules](#51-accessibility-rules)
- [52. Logging Rules](#52-logging-rules)
- [53. Naming Rules](#53-naming-rules)
- [54. File Naming Rules](#54-file-naming-rules)
- [55. Comment Rules](#55-comment-rules)
- [56. Generated Code](#56-generated-code)
- [57. Dependency Injection](#57-dependency-injection)
- [58. Platform-Specific Code](#58-platform-specific-code)
- [59. Android Priority](#59-android-priority)
- [60. Performance Priority](#60-performance-priority)
- [61. Data Integrity](#61-data-integrity)
- [62. Missing Media](#62-missing-media)
- [63. Deletion Rules](#63-deletion-rules)
- [64. Download Storage Rules](#64-download-storage-rules)
- [65. Storage Safety](#65-storage-safety)
- [66. Network Rules](#66-network-rules)
- [67. Cancellation Rules](#67-cancellation-rules)
- [68. Download State Machine](#68-download-state-machine)
- [69. Player State](#69-player-state)
- [70. Database State vs Runtime State](#70-database-state-vs-runtime-state)
- [71. Avoid Premature Optimization](#71-avoid-premature-optimization)
- [72. Avoid Premature Cloud Development](#72-avoid-premature-cloud-development)
- [73. Avoid Premature AI](#73-avoid-premature-ai)
- [74. Agent Behavior](#74-agent-behavior)
- [75. When to Ask for Clarification](#75-when-to-ask-for-clarification)
- [76. No Silent Feature Expansion](#76-no-silent-feature-expansion)
- [77. Acceptance Criteria](#77-acceptance-criteria)
- [78. Final Verification](#78-final-verification)
- [79. Completion Report Format](#79-completion-report-format)
- [80. Final Project Principle](#80-final-project-principle)

---

# 1. Purpose

This document defines the rules, architecture constraints, development workflow, and coding guidelines that AI coding agents must follow when working on MediaHub.

MediaHub is a Flutter-based local-first multimedia application that combines:
- Local media discovery
- Music playback
- Video playback
- Media organization
- Playlists & Favorites
- Playback history & Search
- Download management

The documentation inside the `docs/` directory is the primary technical specification for the project. AI agents must read this file before modifying the project.

---

# 2. Project Overview

| Attribute | Specification |
|---|---|
| **Project Name** | MediaHub |
| **Project Type** | Local-first multimedia application |
| **Primary Platform** | Android |
| **Framework** | Flutter |
| **Language** | Dart |
| **Architecture** | Feature-oriented (Presentation, Application, Domain, Data, Infrastructure) |
| **State Management** | Riverpod |
| **Routing** | GoRouter |
| **Local Database** | Drift (SQLite) |
| **Audio Playback** | `just_audio` with `audio_service` |
| **Video Playback** | `media_kit` |
| **Networking** | `Dio` |

---

# 3. Core Product Concept

MediaHub centralizes three major workflows:

```text
Acquire ──► Manage ──► Consume
```

More specifically:

```text
Supported Source
       │
       ▼
Download Manager
       │
       ▼
  Local File
       │
       ▼
 Media Scanner
       │
       ▼
 Media Library
       │
       ▼
Music / Video Player
```

> [!NOTE]
> The downloader, media library, and players are separate subsystems. A media file must be playable regardless of whether it was downloaded through MediaHub.

---

# 4. Documentation Hierarchy

Before implementing a feature, read the relevant documentation in this order:

```text
AGENTS.md ──► README.md ──► docs/PROJECT.md ──► docs/REQUIREMENTS.md ──► docs/ARCHITECTURE.md ──► docs/TECH_STACK.md ──► Feature Docs ──► docs/ACCEPTANCE_CRITERIA.md
```

### Feature Reading Mapping Table

| Feature Area | Primary Reading Files |
|---|---|
| **Music Player** | `docs/ARCHITECTURE.md`, `docs/TECH_STACK.md`, `docs/ACCEPTANCE_CRITERIA.md` |
| **Downloader** | `docs/ARCHITECTURE.md`, `docs/REQUIREMENTS.md`, `docs/ACCEPTANCE_CRITERIA.md` |
| **Media Library** | `docs/ARCHITECTURE.md`, `docs/REQUIREMENTS.md`, `docs/ACCEPTANCE_CRITERIA.md` |

---

# 5. Documentation Is the Source of Truth

> [!IMPORTANT]
> The documentation defines the intended architecture and scope of the project. Do not silently replace the documented architecture with a different architecture.

If existing code conflicts with the documentation:
1. Inspect the existing implementation.
2. Determine whether the documentation or implementation is outdated.
3. Prefer the most recently established project specification.
4. If the conflict cannot be resolved safely, ask for clarification.

---

# 6. MVP Boundary

The MediaHub MVP is local-first.

> [!WARNING]
> **The MVP must NOT require**:
> User accounts, Authentication, Backend servers, Firebase, Supabase, MongoDB, Cloud databases, Cloud storage, Remote user profiles, or Social networking.

The following must work 100% offline without internet access:
- Local media browsing & searching
- Music playback & Video playback
- Playlist management & Favorites
- Playback history & Local settings

Internet connectivity is only required for network-dependent features, such as media downloads.

---

# 7. Future Versions

Future functionality must not be implemented during the MVP unless explicitly requested.

### V2 — Cloud Metadata Synchronization
Optional cloud sync for Playlists, Favorites, Playback history, Settings, and Media metadata. (Does not imply uploading media files).

### V3 — Cloud Media Synchronization
Optional media upload/download, multi-device synchronization, and cloud storage management.

### V4 — Smart Media Features
Smart playlists, auto organization, duplicate detection, metadata cleanup, AI library management.

---

# 8. Development Philosophy

MediaHub should be developed as a real software project rather than as a single-file prototype.

Prioritize:
1. Correctness
2. Maintainability
3. Simplicity
4. Testability
5. Performance
6. User experience
7. Privacy

---

# 9. Coding Principles

The agent must:
- Follow the documented architecture & folder structure.
- Use meaningful names and keep classes focused.
- Keep business logic, database queries, network calls, and filesystem I/O **OUT** of UI widgets.
- Keep platform-specific functionality isolated.
- Reuse existing services and repositories. Avoid modifying unrelated files.

---

# 10. Flutter Rules

- Use `StatelessWidget` when state is unnecessary.
- Use `StatefulWidget` when local widget state is appropriate.
- Use Riverpod for application state, GoRouter for navigation, Drift for persistent data.

> [!CAUTION]
> Do **NOT** introduce alternative application frameworks (Bloc, Cubit, GetX, MobX, Redux, Provider) without explicit approval.

---

# 11. State Management Rules

Riverpod is the project's state-management solution. Application state flows as:

```text
Widget ──► Riverpod Provider ──► Controller / Notifier ──► Use Case / Repository ──► Service / Database
```

Widgets should consume state rather than directly controlling application services.

---

# 12. Database Rules

MediaHub uses Drift with SQLite to store:
- Media metadata, Playlist info, Playlist relationships, Favorites, Playback history, Playback positions, Download metadata, Application settings.

> [!WARNING]
> The database must **NOT** store MP3/MP4 binary data or large media binaries. Actual media remains in the filesystem.

---

# 13. Media Library Rules

The Media Library and Download Manager are separate systems.
- **Media Library**: Discovers local files, indexes media, extracts metadata, updates records, detects missing files, searches/filters/sorts media.
- **Download Manager**: Validates URLs, detects providers, creates download tasks, downloads files, reports progress, saves completed files.

The downloader must not directly control the library UI.

---

# 14. Downloader Architecture

The downloader uses a modular provider architecture:

```text
URL ──► URL Validator ──► Provider Detector ──► Media Provider ──► Download Manager ──► Local File ──► Media Scanner ──► Media Library
```

```dart
abstract class MediaSourceProvider {
  bool canHandle(Uri url);
  Future<MediaSourceInfo> resolve(Uri url);
  Future<DownloadResult> download(MediaSourceInfo source, DownloadOptions options);
}
```

---

# 15. Downloader Safety Rules

> [!WARNING]
> The downloader must **not** intentionally bypass DRM, authentication, paywalls, or access controls. Provider implementations must be isolated so they can be updated independently if external APIs change.

---

# 16. Player Rules

MediaHub has two primary playback systems:
- **Music Player**: Local audio playback (`just_audio` + `audio_service`).
- **Video Player**: Local video playback (`media_kit`).

Players must operate on local files and must not depend on the downloader.

---

# 17. Music Player Rules

Supports: Play, Pause, Resume, Seek, Previous, Next, Queue, Shuffle, Repeat, Background playback, System media controls, Mini Player, Full Player, Playback history.

---

# 18. Video Player Rules

Supports: Play, Pause, Resume, Seek, Fullscreen, Playback speed, Continue Watching, Saved playback position, Subtitles, Picture-in-picture.

---

# 19. File-System Rules

The implementation must gracefully handle missing files, deleted files, permission errors, invalid paths, corrupted files, and full storage without crashing.

---

# 20. Media Scanner Rules

1. Identify media directories.
2. Scan supported files.
3. Extract metadata.
4. Compare with database records.
5. Upsert new/updated records.
6. Identify missing files.
7. Scanner contains **no UI code**.

---

# 21. Metadata Rules

Metadata should be treated as potentially incomplete. Provide fallback behavior (e.g., if Title tag is missing, use the filename as display title).

---

# 22. UI Rules

Widgets focus strictly on presentation.

```text
PREFERRED: Widget ──► Controller ──► Use Case ──► Repository / Service
AVOID: Widget ──► (Database / HTTP / Filesystem / Downloader / Player directly)
```

---

# 23. Navigation Rules

Navigation must use GoRouter. Routes represent application destinations (`/`, `/library`, `/music`, `/videos`, `/downloads`, `/playlists`, `/favorites`, `/settings`, `/player/music`, `/player/video`).

---

# 24. Dependency Rules

Check Flutter built-ins before adding external packages. When a package is added, update `docs/TECH_STACK.md`.

---

# 25. Security Rules

> [!CAUTION]
> Never hard-code API keys, passwords, tokens, or private secrets into Git. Validate external input, sanitize download filenames, and prevent path traversal.

---

# 26. Download Filename Rules

Sanitize filenames before saving. Prevent path traversal tricks like `../../some-file`. Always save within controlled destination directories.

---

# 27. Error Handling

Handle errors at the appropriate layer (URL validation error, Download error state, Library error state, Player error state). Do not expose raw exception stack traces directly to end users.

---

# 28. User-Facing Errors

Provide clear, friendly messages (e.g., *"Unable to connect to the source. Please check your internet connection and try again."* instead of raw `SocketException`).

---

# 29. Offline Rules

Offline features: Browsing, Searching, Music playback, Video playback, Playlists, Favorites, History, Settings.
Online-only: Remote media resolution & downloading.

---

# 30. Performance Rules

Avoid loading thousands of DB records at once, repeated artwork decoding, or blocking the UI thread with file scanning. Use pagination, lazy loading, and background isolates.

---

# 31. Media Artwork Rules

Cache artwork images. If artwork is unavailable, display a default media icon placeholder.

---

# 32. Background Work

Run expensive operations (scanning directories, metadata parsing, file hashing) asynchronously without freezing the UI.

---

# 33. Database Migration Rules

Database schema changes must use Drift migrations. Do not delete existing SQLite databases to accommodate schema changes.

---

# 34. Repository Rules

Repositories decouple application logic from data sources: `MediaRepository ──► MediaDao ──► Drift`. UI widgets must not call DAOs directly.

---

# 35. Service Rules

Keep services focused (`MediaScanner`, `DownloadManager`, `StorageService`, `AudioService`, `VideoService`, `MetadataService`). Avoid monolith service classes.

---

# 36. Controller Rules

Controllers coordinate feature state and actions using Riverpod notifiers. Controllers must not replace repositories or services.

---

# 37. Testing Rules

After implementing a feature, run:
```bash
flutter analyze
flutter test
```

---

# 38. Testability Rules

Keep business logic testable independently without needing the Flutter UI.

---

# 39. Git Rules

Use semantic commit messages (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`). Never commit secrets, credentials, or temporary build files.

---

# 40. Modification Rules

Understand existing code before editing. Make minimal, surgical edits. Preserve working code and run tests after edits.

---

# 41. Refactoring Rules

Refactor only when it improves clarity, maintainability, or performance. Do not conduct large, unrelated refactors while implementing a feature.

---

# 42. Feature Implementation Workflow

```text
Step 1: Read Docs ──► Step 2: Inspect Code ──► Step 3: Identify Changes ──► Step 4: Implement
       │
       ▼
Step 5: flutter analyze ──► Step 6: flutter test ──► Step 7: Fix Errors ──► Step 8: Verify AC ──► Step 9: Report & Stop
```

---

# 43. Roadmap Rules

Follow the development roadmap in `docs/DEVELOPMENT_PHASES.md`. Implement only the requested phase.

---

# 44. Scope Control

Do not add unrequested features (social feeds, cloud sync, AI features, accounts) during MVP.

---

# 45. Cloud Architecture Rule

The MVP requires no cloud backends (No Firebase, Supabase, MongoDB, PostgreSQL). Maintain clean repository interfaces for future sync.

---

# 46. Local Media Rule

Local files (`.mp3`, `.mp4`) on the user's device are first-class media items and must be fully supported.

---

# 47. Downloader-to-Library Rule

Integrate downloads with the library through the filesystem:
```text
Downloader ──► Save Local File ──► Media Scanner ──► Database ──► Media Library
```

---

# 48. Player Independence Rule

Players operate on local files regardless of how the file was acquired (downloaded, copied, or existing local media).

---

# 49. UI State Rules

Major screens must handle 4 core visual states:
```text
Loading ──► Success ──► Empty ──► Error
```

---

# 50. Empty State Rules

Provide helpful, clear empty state placeholders with CTA actions (e.g. *"Your library is empty. Tap to scan device media."*).

---

# 51. Accessibility Rules

Use semantic labels, accessible contrast ratios, touch target sizes of at least 48x48 dp, and explicit button labels.

---

# 52. Logging Rules

Log errors, unexpected state transitions, and background scanner events. Never log passwords, tokens, or sensitive personal paths in production builds.

---

# 53. Naming Rules

Use clear, descriptive class and variable names (`MediaRepository`, `DownloadController`). Avoid generic names like `Helper`, `Util`, `Thing`, or `Data`.

---

# 54. File Naming Rules

- Files: `snake_case.dart` (e.g., `media_repository.dart`)
- Classes: `PascalCase` (e.g., `MediaRepository`)
- Variables/Methods: `camelCase` (e.g., `getMediaById`)

---

# 55. Comment Rules

Comments explain **why** code exists, not obvious syntax operations.

---

# 56. Generated Code

Do not edit generated code manually (e.g., Drift `.g.dart` files). Run code generation commands when models change.

---

# 57. Dependency Injection

Expose services and repositories through Riverpod providers. Do not instantiate long-lived singletons manually inside widget builders.

---

# 58. Platform-Specific Code

Isolate platform-specific logic behind clear interfaces or services (e.g., permissions, background playback).

---

# 59. Android Priority

Android is the primary target platform for the MVP. Prioritize Android behavior when making platform decisions while keeping Dart portable.

---

# 60. Performance Priority

Never perform synchronous disk I/O, heavy parsing, or database queries inside a widget's `build()` method.

---

# 61. Data Integrity

Reconcile filesystem state with SQLite database records via the Media Scanner.

---

# 62. Missing Media

If a file is missing on disk, mark it as unavailable or allow removing the DB record without throwing fatal errors.

---

# 63. Deletion Rules

> [!IMPORTANT]
> Removing an item from a playlist must **ONLY** remove the playlist-media relationship in SQLite. It must **NEVER** delete the physical media file from storage. Physical file deletion must require an explicit user prompt.

---

# 64. Download Storage Rules

Save downloaded files into designated app download folders. Avoid writing files to random root directories.

---

# 65. Storage Safety

Check available disk space before starting large media downloads. Produce friendly error notifications if space is insufficient.

---

# 66. Network Rules

Network calls must be non-blocking and handle timeouts, HTTP failures, and connection drops cleanly without breaking the local library.

---

# 67. Cancellation Rules

Support cancellation for long operations (downloads, folder scanning). Cleanly reset state when cancelled.

---

# 68. Download State Machine

Represent download task state using explicit enums:
```text
Idle ──► Queued ──► Resolving ──► Downloading ──► Paused ──► Completed / Failed / Cancelled
```

---

# 69. Player State

Player states must use explicit enums: `Idle`, `Loading`, `Playing`, `Paused`, `Completed`, `Error`.

---

# 70. Database State vs Runtime State

- **Database State**: Favorites, Playlists, History, Positions, Download History.
- **Runtime State**: Active player progress, UI loading indicators, active network calls.

---

# 71. Avoid Premature Optimization

Prioritize correctness, maintainability, and clean architecture before optimizing non-critical code paths.

---

# 72. Avoid Premature Cloud Development

Keep the MVP local-first. Do not create server tables or cloud sync logic prematurely.

---

# 73. Avoid Premature AI

Do not add AI recommendation engines or chat UI unless explicitly requested.

---

# 74. Agent Behavior

Agents understand requirements, inspect code, implement minimal robust solutions, run `flutter analyze` & `flutter test`, and report results clearly.

---

# 75. When to Ask for Clarification

Ask clarification only when requirements directly conflict, major architectural changes are requested, or destructive data actions are underspecified.

---

# 76. No Silent Feature Expansion

Implement only the requested feature. Do not expand scope silently.

---

# 77. Acceptance Criteria

Features are complete only when they pass all acceptance criteria defined in `docs/ACCEPTANCE_CRITERIA.md`.

---

# 78. Final Verification Checklist

```text
[ ] Documentation requirements satisfied
[ ] Architecture respected
[ ] No unnecessary dependencies added
[ ] No secrets added
[ ] Error states handled
[ ] Empty states handled
[ ] Relevant tests added
[ ] flutter analyze passes
[ ] flutter test passes
[ ] Acceptance criteria checked
```

---

# 79. Completion Report Format

When submitting work, provide this summary structure:

```text
## Implemented
Description of completed work.

## Files Created
- lib/path/to/file.dart

## Files Modified
- lib/path/to/existing.dart

## Dependencies
- Package additions (if any)

## Database Changes
- Migrations/schema changes (if any)

## Tests Executed
- flutter analyze
- flutter test

## Known Issues
- Any noted caveats

## Next Recommended Task
- Logical next step from docs/DEVELOPMENT_PHASES.md
```

---

# 80. Final Project Principle

<div align="center">

> **Local-First • Modular • Maintainable • Testable • Performant • Privacy-Conscious • User-Focused**

```text
┌─────────────────┐
│ Download System │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Local Files   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Media Scanner  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Media Library  │
└───────┬─┬───────┘
        │ │
        ▼ ▼
 ┌──────────────┐ ┌──────────────┐
 │ Music Player │ │ Video Player │
 └──────────────┘ └──────────────┘
```

</div>
