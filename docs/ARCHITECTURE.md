<div align="center">

# 🏛️ MediaHub — System Architecture Specification

[![Document Version](https://img.shields.io/badge/Doc_Type-Architecture-00599C?style=for-the-badge)](docs/ARCHITECTURE.md)
[![Pattern](https://img.shields.io/badge/Pattern-Clean_Feature--Oriented-2E7D32?style=for-the-badge)]()
[![Persistence](https://img.shields.io/badge/Persistence-Drift_SQLite-FF6F00?style=for-the-badge)](docs/ARCHITECTURE.md)

---

**Comprehensive technical specification for MediaHub's feature-oriented clean architecture, state management flow, persistence model, and subsystem boundaries.**

</div>

---

## 📑 Table of Contents

- [1. Purpose](#1-purpose)
- [2. High-Level Architecture](#2-high-level-architecture)
- [3. System Subsystems](#3-system-subsystems)
- [4. Architectural Layers](#4-architectural-layers)
- [5. Presentation Layer](#5-presentation-layer)
- [6. Application Layer](#6-application-layer)
- [7. Domain Layer](#7-domain-layer)
- [8. Data Layer](#8-data-layer)
- [9. Infrastructure Layer](#9-infrastructure-layer)
- [10. Data Source Strategy](#10-data-source-strategy)
- [11. Media Storage Model](#11-media-storage-model)
- [12. Local File System](#12-local-file-system)
- [13. Local Database (Drift + SQLite)](#13-local-database-drift--sqlite)
- [14. Database Entities](#14-database-entities)
- [15. Media Scanner Architecture](#15-media-scanner-architecture)
- [16. Scanner Workflow](#16-scanner-workflow)
- [17. Metadata Extraction](#17-metadata-extraction)
- [18. Media Library Architecture](#18-media-library-architecture)
- [19. Library Workflow](#19-library-workflow)
- [20. Music Player Architecture](#20-music-player-architecture)
- [21. Music Player Components](#21-music-player-components)
- [22. Video Player Architecture](#22-video-player-architecture)
- [23. Video Player Components](#23-video-player-components)
- [24. Downloader Architecture](#24-downloader-architecture)
- [25. Downloader Components](#25-downloader-components)
- [26. Media Source Provider System](#26-media-source-provider-system)
- [27. Downloader Workflow](#27-downloader-workflow)
- [28. Download State](#28-download-state)
- [29. Download-to-Library Flow](#29-download-to-library-flow)
- [30. Playlist Architecture](#30-playlist-architecture)
- [31. Favorites Architecture](#31-favorites-architecture)
- [32. Playback History Architecture](#32-playback-history-architecture)
- [33. Search Architecture](#33-search-architecture)
- [34. Library Synchronization](#34-library-synchronization)
- [35. State Management](#35-state-management)
- [36. Dependency Injection](#36-dependency-injection)
- [37. Error Handling Architecture](#37-error-handling-architecture)
- [38. Error Categories](#38-error-categories)
- [39. Logging](#39-logging)
- [40. Testing Architecture](#40-testing-architecture)
- [41. Testable Dependencies](#41-testable-dependencies)
- [42. Feature-Oriented Structure](#42-feature-oriented-structure)
- [43. Recommended Project Structure](#43-recommended-project-structure)
- [44. Feature Structure](#44-feature-structure)
- [45. Core vs Feature Code](#45-core-vs-feature-code)
- [46. Shared Components](#46-shared-components)
- [47. Application Startup](#47-application-startup)
- [48. Navigation Architecture](#48-navigation-architecture)
- [49. Media Detail Architecture](#49-media-detail-architecture)
- [50. Media Deletion](#50-media-deletion)
- [51. Cache Architecture](#51-cache-architecture)
- [52. Temporary Download Files](#52-temporary-download-files)
- [53. Concurrency](#53-concurrency)
- [54. Background Operations](#54-background-operations)
- [55. Resource Management](#55-resource-management)
- [56. Platform Abstraction](#56-platform-abstraction)
- [57. Desktop Considerations](#57-desktop-considerations)
- [58. Mobile Considerations](#58-mobile-considerations)
- [59. Offline Architecture](#59-offline-architecture)
- [60. Future Cloud Synchronization](#60-future-cloud-synchronization)
- [61. Future Multi-Device Architecture](#61-future-multi-device-architecture)
- [62. Architecture Evolution](#62-architecture-evolution)
- [63. Dependency Direction](#63-dependency-direction)
- [64. Example: Playing a Song](#64-example-playing-a-song)
- [65. Example: Scanning the Library](#65-example-scanning-the-library)
- [66. Example: Creating a Playlist](#66-example-creating-a-playlist)
- [67. Example: Downloading Media](#67-example-downloading-media)
- [68. Architecture Boundaries](#68-architecture-boundaries)
- [69. Practical Abstraction Rule](#69-practical-abstraction-rule)
- [70. MVP Architecture Priority](#70-mvp-architecture-priority)
- [71. Recommended Architecture for MVP](#71-recommended-architecture-for-mvp)
- [72. Architecture Success Criteria](#72-architecture-success-criteria)
- [73. Final Architecture Principle](#73-final-architecture-principle)

---

# 1. Purpose

This document defines the software architecture of MediaHub.

MediaHub is a local-first multimedia application designed to acquire, organize, manage, and play personal media.

The architecture described in this document prioritizes:
- 📱 Local-first behavior
- 🧱 Modular feature boundaries
- 🧪 Maintainability and testability
- ⚡ Performance with large collections
- 🔒 Data privacy

---

# 2. High-Level Architecture

MediaHub is organized into distinct subsystems:

```text
┌─────────────────────────────────────────────────────────────┐
│                       Presentation                          │
│                   (Pages, Widgets, UI)                      │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                        Application                          │
│                (Controllers, Riverpod State)                │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                           Domain                            │
│                 (Entities, Use Cases, Rules)                │
└───────────────────────┬─────────────┬───────────────────────┘
                        │             │
                        ▼             ▼
┌───────────────────────────┐     ┌───────────────────────────┐
│           Data            │     │      Infrastructure       │
│  (Repositories, DAOs)     │     │ (SQLite, Filesystem, Player)│
└───────────────────────────┘     └───────────────────────────┘
```

---

# 3. System Subsystems

MediaHub consists of seven primary subsystems:

1. 📚 **Media Library Subsystem**: Indexes local files, extracts metadata, powers searching and filtering.
2. 📥 **Download Subsystem**: Validates URLs, resolves media sources, executes downloads.
3. 🎵 **Music Player Subsystem**: Manages audio playback queues, background controls, mini player.
4. 🎬 **Video Player Subsystem**: Manages video rendering, playback controls, fullscreen mode.
5. 📑 **Playlist Subsystem**: Organizes tracks into custom user collections.
6. ❤️ **Favorites Subsystem**: Manages bookmarked tracks and clips.
7. ⏱️ **Playback History Subsystem**: Records played media timestamps and resume positions.

> [!NOTE]
> These subsystems communicate through defined contracts rather than directly manipulating each other's internal states.

---

# 4. Architectural Layers

| Layer | Responsibility | Dependencies |
|---|---|---|
| **Presentation** | Displays UI, captures user input, listens to state | Application layer |
| **Application** | Coordinates app state, exposes Riverpod providers | Domain layer |
| **Domain** | Contains pure business logic, entities, and use cases | None (Independent) |
| **Data** | Implements repositories, communicates with SQLite DAOs | Domain & Infrastructure |
| **Infrastructure** | Implements storage, player engines, network adapters | Direct system APIs |

---

# 5. Presentation Layer
Contains Flutter pages, dialogs, mini players, and reusable widgets. Receives state updates from Riverpod providers.

# 6. Application Layer
Contains feature controllers (e.g., `LibraryController`, `MusicPlayerController`, `DownloadController`). Translates UI events into domain use case calls.

# 7. Domain Layer
Pure Dart layer containing core entities (`MediaItem`, `Playlist`, `DownloadTask`) and business use cases (`PlayMediaUseCase`, `ScanLibraryUseCase`, `StartDownloadUseCase`).

# 8. Data Layer
Translates domain models to data models and interfaces with local Drift SQLite tables via DAOs (`MediaDao`, `PlaylistDao`).

# 9. Infrastructure Layer
Handles raw hardware and package interactions (`Dio` HTTP client, `just_audio` player engine, `media_kit` video player, `path_provider` filesystem).

---

# 10. Data Source Strategy

MediaHub prioritizes local data sources:

```text
Repository ──► Local Data Source (SQLite / Filesystem)
```

In future versions (V2/V3), remote data sources can be attached behind repository abstractions without changing UI logic:

```text
Repository ├──► Local Data Source (SQLite / Filesystem)
           └──► Remote Data Source (Cloud API)
```

---

# 11. Media Storage Model

Dual storage model:
- **Device Filesystem**: Holds physical `.mp3`, `.mp4`, `.flac` binary files.
- **Drift SQLite DB**: Holds metadata references, file paths, playlists, and history.

> [!WARNING]
> Media files are **never** stored directly inside SQLite database columns.

---

# 12. Local File System
Stores raw downloaded media files in configured directories (e.g., `Music/`, `Videos/`, `MediaHub/Downloads/`).

# 13. Local Database (Drift + SQLite)
Provides type-safe persistence across device reboots for media records, playlists, favorites, and history.

---

# 14. Database Entities

### Media Schema (`media_items` table)
```text
id (Text, Primary Key)
path (Text, Unique)
title (Text)
artist (Text, Nullable)
album (Text, Nullable)
genre (Text, Nullable)
duration (Int, Nullable)
mediaType (Text - Audio/Video)
artworkPath (Text, Nullable)
fileSize (Int)
dateAdded (DateTime)
lastPlayed (DateTime, Nullable)
```

### Playlist Schema (`playlists` & `playlist_items` tables)
```text
playlists: id, name, createdAt
playlist_items: id, playlistId, mediaId, sortOrder
```

---

# 15. Media Scanner Architecture
Identifies configured storage directories, detects supported files, extracts tags, and upserts metadata into SQLite.

# 16. Scanner Workflow
```text
Scan Directory ──► Find Supported Files ──► Compare with DB ──► Extract Metadata ──► Upsert SQLite
```

# 17. Metadata Extraction
Uses tag reading libraries to extract ID3 tags, cover art, and video dimensions. Fallback: Uses filename if title tag is absent.

---

# 18. Media Library Architecture
Queries indexed metadata from SQLite. Supports fast pagination, searching, filtering, and sorting.

# 19. Library Workflow
```text
User Search/Filter ──► Controller ──► MediaRepository ──► Drift SQLite Query ──► UI Display
```

---

# 20. Music Player Architecture
Controls audio playback independently of file origin.

# 21. Music Player Components
```text
MusicPlayerWidget ──► MusicPlayerNotifier ──► AudioService ──► just_audio Engine
```

---

# 22. Video Player Architecture
Controls video playback rendering and fullscreen toggle.

# 23. Video Player Components
```text
VideoPlayerPage ──► VideoPlayerNotifier ──► media_kit Engine
```

---

# 24. Downloader Architecture
Modular downloader subsystem isolated from library logic.

# 25. Downloader Components
- **URL Validator**: Validates syntax and supported domain patterns.
- **Provider Detector**: Matches URL to appropriate resolution provider.
- **Download Task Manager**: Manages queue, progress, pause, resume, retry.

---

# 26. Media Source Provider System

```dart
abstract class MediaSourceProvider {
  bool canHandle(Uri url);
  Future<MediaSourceInfo> resolve(Uri url);
  Future<DownloadResult> download(MediaSourceInfo source, DownloadOptions options);
}
```

---

# 27. Downloader Workflow
```text
URL Input ──► Validate ──► Detect Provider ──► Resolve Info ──► Queue Task ──► Execute Download ──► Save File
```

# 28. Download State
Enums: `Queued`, `Resolving`, `Downloading`, `Paused`, `Completed`, `Failed`, `Cancelled`.

# 29. Download-to-Library Flow
```text
Completed Download ──► Local File ──► Scanner ──► Extract Metadata ──► Insert SQLite ──► Library UI
```

---

# 30. Playlist Architecture
Playlists maintain media ID references. Deleting a playlist or item **never** deletes physical files.

# 31. Favorites Architecture
Bookmarked state stored as boolean/metadata flags in SQLite.

# 32. Playback History Architecture
Stores `mediaId`, `lastPlayed` timestamp, and `playbackPosition` seek offset.

# 33. Search Architecture
Queries SQLite indexed columns (`title`, `artist`, `album`, `genre`) without loading media binaries into memory.

# 34. Library Synchronization
Reconciles SQLite records with disk storage during scanner passes.

---

# 35. State Management
Riverpod is used exclusively for application state flow:
```text
Widget ──► Riverpod Notifier / Provider ──► Domain Use Case ──► Data Repository
```

# 36. Dependency Injection
Dependencies provided declaratively via Riverpod providers.

---

# 37. Error Handling Architecture
Low-level data/network exceptions mapped to domain errors:
```text
Filesystem / Socket Error ──► Data Layer ──► Domain Error ──► UI Friendly Error Message
```

# 38. Error Categories
`FilesystemError`, `DatabaseError`, `PlaybackError`, `DownloadError`, `ValidationError`, `PermissionError`, `NetworkError`.

---

# 39. Logging
Structured logging during development. Suppressed sensitive credentials or personal data in release builds.

---

# 40. Testing Architecture
Layered testing strategy:
- Unit Tests: Domain use cases, services, URL resolution.
- Repository Tests: Drift DAOs & DB migrations.
- Widget Tests: Presentation UI state rendering.
- Integration Tests: End-to-end user flows.

# 41. Testable Dependencies
Abstract interfaces used for services (`PlaybackService`, `DownloadService`, `StorageService`).

---

# 42. Feature-Oriented Structure
Code organized by feature directory rather than generic global type folders.

# 43. Recommended Project Structure
```text
lib/
├── app/          # App config, routes, theme
├── core/         # Shared utils, errors, constants
├── data/         # Drift DB, DAOs, schema
├── domain/       # Core entities, use cases
└── features/     # Feature modules (library, player, downloads, playlists, history)
```

# 44. Feature Structure
Complex features contain `data/`, `domain/`, `presentation/` sub-directories.

# 45. Core vs Feature Code
`core/` contains truly shared application infrastructure.

# 46. Shared Components
`shared/widgets/` holds reusable UI elements (`MediaCard`, `ErrorView`, `EmptyState`).

---

# 47. Application Startup
```text
main() ──► Flutter Init ──► Riverpod Container ──► DB Init ──► Settings Init ──► GoRouter ──► UI Page
```

# 48. Navigation Architecture
GoRouter handles declarative routing across pages (`/library`, `/downloads`, `/playlists`, `/settings`).

# 49. Media Detail Architecture
Media metadata modal/screen for inspecting tags, file path, size, date added.

# 50. Media Deletion
- **Remove from Library**: Removes SQLite record; keeps physical file.
- **Delete File**: Explicit confirmation required; deletes disk file and SQLite record.

# 51. Cache Architecture
Temporary cache directory holds artwork thumbnails and incomplete download chunks.

# 52. Temporary Download Files
Downloads save to `.tmp` files and rename to final extensions upon completion.

# 53. Concurrency
Background operations run asynchronously without blocking the UI thread.

# 54. Background Operations
Scanning, downloading, and thumbnail generation run non-blockingly.

# 55. Resource Management
File handles, audio players, video renderers, and streams disposed cleanly when unused.

# 56. Platform Abstraction
Isolate platform permissions, notification channels, and file pickers.

# 57. Desktop Considerations
Support resizable windows, keyboard shortcuts, mouse hover states, and desktop file dialogs.

# 58. Mobile Considerations
Support bottom navigation, touch gestures, system media notifications, and mobile permissions.

# 59. Offline Architecture
All local media management and playback functions 100% offline.

# 60. Future Cloud Synchronization
V2/V3 sync engine will attach via remote repositories without touching domain/UI contracts.

# 61. Future Multi-Device Architecture
Optional cross-device sync reserved for future roadmap.

# 62. Architecture Evolution
Simple, clean local-first architecture without premature microservice complexity.

# 63. Dependency Direction
Dependencies point inward: `Presentation ──► Application ──► Domain ◄── Data`.

---

# 64. Workflow Example: Playing a Song
```text
User Taps Song ──► Library Page ──► Controller ──► PlayMedia Use Case ──► AudioService ──► just_audio Engine ──► Playing
```

# 65. Workflow Example: Scanning Library
```text
User Triggers Scan ──► Scan Library Use Case ──► MediaScanner Service ──► Scan Disk ──► Metadata Extractor ──► Upsert SQLite ──► UI Refresh
```

# 66. Workflow Example: Creating a Playlist
```text
User Creates Playlist ──► Controller ──► CreatePlaylist Use Case ──► PlaylistRepository ──► Insert SQLite ──► UI Refresh
```

# 67. Workflow Example: Downloading Media
```text
URL Input ──► Download Controller ──► Start Download ──► Provider Resolver ──► Dio Download ──► Temp File ──► Rename File ──► Scanner ──► SQLite ──► Library UI
```

---

# 68. Architecture Boundaries

```text
UI ───────X─────── Direct SQLite Access
UI ───────X─────── Direct Disk File Access
UI ───────X─────── Direct Downloader Service
Domain ───X─────── Flutter Widgets
```

---

# 69. Practical Abstraction Rule
Create interfaces when they provide genuine testability or platform swap value. Avoid dogmatic redundant abstractions.

---

# 70. MVP Architecture Priority
1. Working local library
2. Working playback
3. Working download manager
4. Working playlists & history
5. Robust SQLite persistence

---

# 71. Recommended Architecture for MVP

```text
Flutter UI
    │
    ▼
Riverpod Notifiers & Controllers
    │
    ▼
Domain Use Cases & Services
    │
    ▼
Repositories
    │
    ├──────────► Drift SQLite DB
    ├──────────► Device Filesystem
    ├──────────► Audio / Video Engines
    └──────────► Dio Downloader
```

---

# 72. Architecture Success Criteria

- Features added cleanly without breaking existing logic.
- UI code is clean and simple.
- Business logic is testable in isolation.
- Media management functions 100% offline.

---

# 73. Final Architecture Principle

<div align="center">

> **MediaHub uses architecture to manage complexity, not to create complexity.**

</div>
