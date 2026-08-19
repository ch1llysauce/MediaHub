<div align="center">

# 🛠️ MediaHub — Technology Stack Specification

[![Document Version](https://img.shields.io/badge/Doc_Type-Tech_Stack-00599C?style=for-the-badge)](docs/TECH_STACK.md)
[![Framework](https://img.shields.io/badge/Framework-Flutter_3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Database](https://img.shields.io/badge/Database-Drift_SQLite-FF6F00?style=for-the-badge&logo=sqlite&logoColor=white)](https://drift.simonbinder.eu/)

---

**Comprehensive technical specification, rationale, and dependency analysis for MediaHub's core frameworks, local persistence engine, multimedia libraries, state management, and networking.**

</div>

---

## 📑 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Framework & Core Language](#2-framework--core-language)
- [3. Primary Platform](#3-primary-platform)
- [4. State Management](#4-state-management)
- [5. Navigation](#5-navigation)
- [6. Local Persistence](#6-local-persistence)
- [7. Database Engine](#7-database-engine)
- [8. Audio Playback](#8-audio-playback)
- [9. Background Audio](#9-background-audio)
- [10. Video Playback](#10-video-playback)
- [11. Networking](#11-networking)
- [12. File System Management](#12-file-system-management)
- [13. Permissions](#13-permissions)
- [14. Media Scanner](#14-media-scanner)
- [15. Download Engine](#15-download-engine)
- [16. Provider Resolution](#16-provider-resolution)
- [17. Image Caching](#17-image-caching)
- [18. Dependency Injection Strategy](#18-dependency-injection-strategy)
- [19. Testing Stack](#19-testing-stack)
- [20. Package Selection Rationale](#20-package-selection-rationale)
- [21. Core Dependencies Matrix](#21-core-dependencies-matrix)
- [22. Dev Dependencies Matrix](#22-dev-dependencies-matrix)
- [23. State Management Selection](#23-state-management-selection)
- [24. Database Selection](#24-database-selection)
- [25. Audio Engine Selection](#25-audio-engine-selection)
- [26. Video Engine Selection](#26-video-engine-selection)
- [27. Networking Selection](#27-networking-selection)
- [28. Navigation Selection](#28-navigation-selection)
- [29. Cloud MVP Strategy](#29-cloud-mvp-strategy)
- [30. Future Cloud Stack](#30-future-cloud-stack)
- [31. Future Synchronization Architecture](#31-future-synchronization-architecture)
- [32. Recommended Folder Architecture](#32-recommended-folder-architecture)
- [33. Feature Structure](#33-feature-structure)
- [34. Dependency Direction](#34-dependency-direction)
- [35. Repository Pattern](#35-repository-pattern)
- [36. Service Responsibilities](#36-service-responsibilities)
- [37. Error Handling](#37-error-handling)
- [38. Logging](#38-logging)
- [39. Performance Considerations](#39-performance-considerations)
- [40. Background Operations](#40-background-operations)
- [41. Platform Strategy](#41-platform-strategy)
- [42. Security and Privacy](#42-security-and-privacy)
- [43. Dependency Selection Principle](#43-dependency-selection-principle)
- [44. MVP Dependency Philosophy](#44-mvp-dependency-philosophy)
- [45. Development Commands](#45-development-commands)
- [46. Technology Decision Summary](#46-technology-decision-summary)
- [47. Final Technology Principle](#47-final-technology-principle)

---

## 1. Purpose

This document defines the official technology stack of MediaHub.

MediaHub is a local-first multimedia application that combines:
- Local media discovery
- Music playback
- Video playback
- Media organization
- Playlists & Favorites
- Playback history & Search
- Download management

The tech stack selected in this document reflects the core project principles:
- 📱 Local-first capabilities
- 🔒 Privacy focus
- 🧱 High maintainability
- ⚡ Performant execution
- 🧪 Strong testability

---

## 2. Framework & Core Language

- **Framework**: **Flutter** (Cross-platform UI engine producing native binaries for Android and Desktop).
- **Core Language**: **Dart 3.x** (Strongly typed, compiled language with sound null safety, async/await, isolates, and pattern matching).

---

## 3. Primary Platform

> [!IMPORTANT]
> **Android Priority**: The primary target platform for the MVP is **Android**. Cross-platform portability (Desktop/Windows) is maintained through clean Flutter architecture.

---

## 4. State Management

- **Technology**: **Riverpod**
- **Justification**: Compile-time safe state management without context dependencies. Simplifies state notification and dependency injection.

---

## 5. Navigation

- **Technology**: **GoRouter**
- **Justification**: Official declarative routing package for Flutter supporting deep-linking, type-safe path parameters, and shell navigation routes.

---

## 6. Local Persistence & 7. Database Engine

- **Technology**: **Drift + SQLite**
- **Justification**: Drift provides a type-safe Dart wrapper over SQLite, generating reactive stream queries, migrations, and strongly typed SQL DAOs.

---

## 8. Audio Playback & 9. Background Audio

- **Technologies**: **`just_audio`** + **`audio_service`**
- **Justification**: `just_audio` provides robust local audio playback with seeking, queues, shuffle, and repeat. `audio_service` handles system media notifications and background playback control.

---

## 10. Video Playback

- **Technology**: **`media_kit`**
- **Justification**: High-performance video playback engine based on `libmpv`, offering native hardware acceleration across Android and Desktop platforms.

---

## 11. Networking

- **Technology**: **Dio**
- **Justification**: Powerful HTTP client supporting progress tracking, interceptors, task cancellation, and custom timeout configuration needed by the Download Manager.

---

## 12. File System Management & 13. Permissions

- **Technologies**: **`path_provider`** + **`permission_handler`**
- **Justification**: `path_provider` resolves platform-specific storage paths (`ApplicationDocumentsDirectory`, `ExternalStorageDirectory`). `permission_handler` safely manages Android storage and media permissions.

---

## 14. Media Scanner & 15. Download Engine

Custom internal Dart services utilizing background isolates and asynchronous file I/O.

---

## 16. Provider Resolution

Modular Dart provider system separating URL resolution from downloading logic.

---

## 17. Image Caching

- **Technology**: **`cached_network_image`** / Custom artwork file caching.

---

## 18. Dependency Injection Strategy

Declarative Riverpod providers pass repositories and services down to controllers and widgets without manual singleton constructors.

---

## 19. Testing Stack

- **Unit Testing**: `flutter_test`, `mockito` / `mocktail`.
- **Database Testing**: Drift in-memory SQLite database.
- **Widget Testing**: `flutter_test`.

---

## 20. Package Selection Rationale

| Domain | Selected Technology | Alternative Evaluated | Why Selected? |
|---|---|---|---|
| State | **Riverpod** | Bloc / Provider | Cleaner syntax, compile-time safety, no BuildContext dependency |
| DB | **Drift (SQLite)** | Hive / Isar / Realm | SQL relational support, strong type generation, schema migration control |
| Audio | **`just_audio`** | `audioplayers` | Superior background audio support & system controls integration |
| Video | **`media_kit`** | `video_player` | Native hardware acceleration on desktop & wider codec support |
| HTTP | **Dio** | `http` package | Built-in download progress stream callback & cancellation tokens |

---

## 21. Core Dependencies Matrix

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0
  drift: ^2.16.0
  sqlite3_flutter_libs: ^0.5.0
  just_audio: ^0.9.36
  audio_service: ^0.18.12
  media_kit: ^1.1.10
  media_kit_video: ^1.2.4
  media_kit_libs_video: ^1.0.4
  dio: ^5.4.0
  path_provider: ^2.1.2
  permission_handler: ^11.3.0
```

---

## 22. Dev Dependencies Matrix

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  drift_dev: ^2.16.0
  build_runner: ^2.4.8
  flutter_lints: ^3.0.0
  mocktail: ^1.0.3
```

---

## 23. State Management Selection

```dart
// Example Riverpod State Provider Flow
final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  final mediaRepository = ref.watch(mediaRepositoryProvider);
  return LibraryNotifier(mediaRepository);
});
```

---

## 24. Database Selection

```sql
-- Example Drift SQL Table Definition
CREATE TABLE media_items (
    id TEXT NOT NULL PRIMARY KEY,
    path TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    artist TEXT,
    album TEXT,
    genre TEXT,
    duration INTEGER,
    media_type TEXT NOT NULL,
    artwork_path TEXT,
    file_size INTEGER NOT NULL,
    date_added DATETIME NOT NULL,
    last_played DATETIME
);
```

---

## 25. Audio Engine Selection & 26. Video Engine Selection

Isolated player engines handling local file streams cleanly without UI thread lag.

---

## 27. Networking Selection & 28. Navigation Selection

Dio HTTP progress stream handling and GoRouter route configuration.

---

## 29. Cloud MVP Strategy

> [!IMPORTANT]
> **No Cloud for MVP**: The MVP operates 100% offline without remote backends, Firebase, or MongoDB, ensuring privacy, simplicity, and low cost.

---

## 30. Future Cloud Stack & 31. Future Synchronization Architecture

- **V2**: Cloud Metadata Sync (Playlists, History, Favorites).
- **V3**: Cloud Media File Sync (Optional cloud backup).

---

## 32. Recommended Folder Architecture

```text
lib/
├── app/          # App config, routes, theme
├── core/         # Shared utils, errors, constants
├── data/         # Drift DB, DAOs, schema
├── domain/       # Core entities, use cases
└── features/     # Feature modules (library, player, downloads, playlists, history)
```

---

## 33. Feature Structure

Features contain modular `data/`, `domain/`, `presentation/` directories.

---

## 34. Dependency Direction

`Presentation ──► Application ──► Domain ◄── Data ──► Infrastructure`

---

## 35. Repository Pattern

```text
UI ──► Use Case ──► MediaRepository ──► Drift SQLite DAO
```

---

## 36. Service Responsibilities

Focused, single-responsibility services (`MediaScannerService`, `DownloadService`, `AudioService`, `VideoService`).

---

## 37. Error Handling & 38. Logging

Low-level technical errors converted into user-friendly UI error cards. Structured logs active during dev builds.

---

## 39. Performance Considerations & 40. Background Operations

Asynchronous isolate scanning, lazy widget rendering, cached artwork, streamed video playback.

---

## 41. Platform Strategy & 42. Security & Privacy

Local media privacy by default. Isolated platform permissions. No hardcoded secrets.

---

## 43. Dependency Selection Principle & 44. MVP Dependency Philosophy

Keep the dependency footprint small, stable, and well-maintained.

---

## 45. Development Commands

```bash
# Verify Flutter
flutter --version

# Fetch pub packages
flutter pub get

# Run build runner for Drift DB code gen
dart run build_runner build --delete-conflicting-outputs

# Run Flutter app
flutter run

# Run static analysis & test suite
flutter analyze
flutter test
```

---

## 46. Technology Decision Summary

```text
┌───────────────────────────────┐
│            Flutter            │
│             Dart              │
├───────────────────────────────┤
│           Riverpod            │
│           GoRouter            │
├───────────────────────────────┤
│       Feature Modules         │
├───────────────────────────────┤
│          Use Cases            │
├───────────────────────────────┤
│         Repositories          │
├───────────────────────────────┤
│ Drift / SQLite                │
│ Filesystem                    │
│ Download Services             │
│ Media Services (`just_audio` / `media_kit`) │
├───────────────────────────────┤
│       Device Storage          │
└───────────────────────────────┘
```

---

## 47. Final Technology Principle

<div align="center">

> **MediaHub should use technology that supports its core purpose rather than adding technology simply for the sake of complexity.**

</div>