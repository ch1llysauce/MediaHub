<div align="center">

# 🎧 MediaHub

**Centralized Local-First Multimedia Application**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-00599C?style=for-the-badge)](https://riverpod.dev)
[![Drift SQLite](https://img.shields.io/badge/Database-Drift_SQLite-003B5C?style=for-the-badge&logo=sqlite&logoColor=white)](https://drift.simonbinder.eu/)
[![Architecture](https://img.shields.io/badge/Architecture-Local--First-2E7D32?style=for-the-badge)](docs/ARCHITECTURE.md)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Desktop-FF6F00?style=for-the-badge&logo=android&logoColor=white)](https://flutter.dev)

---

MediaHub is a local-first multimedia application designed to centralize the acquisition, organization, management, and playback of personal music and video content.

Instead of relying on separate applications for downloading, organizing, and consuming media, MediaHub provides a unified multimedia library where users can manage and play their locally stored audio and video files.

</div>

---

## 📑 Table of Contents

- [📱 Project Overview](#-project-overview)
- [🎯 Project Goals](#-project-goals)
- [✨ Core Features](#-core-features)
- [🏗️ Local-First Architecture](#%EF%B8%8F-local-first-architecture)
- [💾 Storage & Database](#-storage--database)
- [🎯 MVP Scope](#-mvp-scope)
- [🚀 Future Versions](#-future-versions)
- [🛠️ Technology Stack](#%EF%B8%8F-technology-stack)
- [🏛️ Project Architecture & Structure](#%EF%B8%8F-project-architecture--structure)
- [💡 Development Philosophy](#-development-philosophy)
- [💻 Development Commands](#-development-commands)
- [🗺️ Development Roadmap](#%EF%B8%8F-development-roadmap)
- [📚 Documentation Index](#-documentation-index)
- [📊 Current Status & Portfolio Value](#-current-status--portfolio-value)

---

## 📱 Project Overview

MediaHub combines four major capabilities into one application:

1. 📥 **Download Manager**
2. 📚 **Media Library**
3. 🎵 **Music Player**
4. 🎬 **Video Player**

### Core Download & Ingestion Workflow

```text
┌─────────────────────────────────────────────────────────────┐
│                       Media Sources                         │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                      Download Manager                       │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                         Local Files                         │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                        Media Scanner                        │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                        Media Library                        │
└───────────────────────┬─────────────┬───────────────────────┘
                        │             │
                        ▼             ▼
         ┌───────────────────┐   ┌───────────────────┐
         │   Music Player    │   │   Video Player    │
         └───────────────────┘   └───────────────────┘
```

> [!NOTE]
> **Existing Local Files Support**: MediaHub can also work directly with media files that already exist on the user's device without requiring download through the app.

```text
Existing Local Media ──► Media Scanner ──► Media Library ──► Music Player / Video Player
```

---

## 🎯 Project Goals

The primary goal of MediaHub is to create a centralized multimedia application that provides a complete local media experience.

The project aims to demonstrate practical software engineering concepts including:

* 📱 **Flutter & Dart Development**
* 🏗️ **Local-First Application Architecture**
* 💾 **Local Database Management (Drift + SQLite)**
* 📁 **Filesystem Management & Permissions**
* 🎧 **Multimedia Playback (`just_audio` & `media_kit`)**
* 📥 **Download Management & Provider Abstraction**
* ⚡ **State Management with Riverpod**
* 🔄 **Asynchronous Programming & Background Isolates**
* 🛡️ **Graceful Error Handling & Recovery**
* 🧪 **Automated Testing Strategy**
* 🧱 **Modular Clean Architecture**

> [!TIP]
> MediaHub is engineered as a **portfolio-quality project** demonstrating solid software design principles rather than a simple single-file prototype.

---

## ✨ Core Features

### 1. 📚 Media Library
MediaHub automatically discovers supported media files stored on the device.
* **Content Support**: Music, Videos, Albums, Artists, Genres, Favorites.
* **Discovery Features**: Recently added media, Recently played media.
* **Search & Filter**: Real-time search, multi-property filtering, flexible sorting.
* **Data Principle**: Stores metadata references in SQLite without duplicating binary media files.

### 2. 📥 Download Manager
MediaHub includes an independent download manager for supported media sources.
* **URL Handling**: URL input, validation, and automated provider detection.
* **Queue Control**: Download queue with Progress, Pause, Resume, Cancel, Retry options.
* **State Management**: Dedicated states for Queued, Resolving, Downloading, Completed, and Failed tasks.
* **Integration**: Downloaded files seamlessly auto-index into the local Media Library via the scanner.

### 3. 🎵 Music Player
Provides a complete audio playback experience for locally stored audio files.
* **Playback Controls**: Play, Pause, Resume, Seek, Previous, Next, Volume control.
* **Queue & Modes**: Queue management, Shuffle, Repeat (All / One / Off).
* **UI Experiences**: Persistent Mini Player, Full Player view with artwork & progress.
* **System Integration**: Background audio playback, System media controls / notifications, Playback history.

### 4. 🎬 Video Player
A dedicated local video playback engine independent of the music player.
* **Playback Controls**: Play, Pause, Resume, Seek, Fullscreen toggle.
* **Advanced Features**: Playback speed adjustment (`0.5x` to `2.0x`), Playback position saving, "Continue Watching".

### 5. 📑 Playlists
Organize local audio and video media into custom playlists.
* Create, rename, and delete playlists.
* Add or remove media items (without deleting physical media files).
* Reorder items within playlists and start playlist playback.
* Persistent local storage.

### 6. ❤️ Favorites
Mark favorite music tracks and video clips for quick access.
* Works seamlessly across both audio and video media.
* Persistent favorite status saved in SQLite.

### 7. ⏱️ Playback History
Tracks user playback activity to support smart app features.
* Stores Media ID, Last Played Time, Playback Position, and Media Type.
* Powers "Recently Played", "Continue Watching", and "Resume Playback" capabilities.

---

## 🏗️ Local-First Architecture

MediaHub is designed as a **local-first application**.

> [!IMPORTANT]
> **No Backend Required for MVP**: The MVP does not require a backend server, user accounts, or cloud infrastructure. All core media operations run completely offline.

| Feature Category | Works Completely Offline? | Requires Internet? |
|---|:---:|:---:|
| Browsing Media Library | ✅ Yes | ❌ No |
| Searching & Filtering | ✅ Yes | ❌ No |
| Music Playback | ✅ Yes | ❌ No |
| Video Playback | ✅ Yes | ❌ No |
| Playlist Management | ✅ Yes | ❌ No |
| Favorites & History | ✅ Yes | ❌ No |
| Local Application Settings | ✅ Yes | ❌ No |
| Downloading Online Media | ❌ No | ✅ Yes |

---

## 💾 Storage & Database

MediaHub uses a dual-layer storage strategy:
1. **Device Filesystem**: Holds physical `.mp3`, `.mp4`, `.flac`, `.mkv` media binaries.
2. **SQLite Database (via Drift)**: Stores application metadata, playlists, favorites, history, and settings.

### Storage Layout Example

```text
Device Storage/
├── Music/
│   ├── song1.mp3
│   └── song2.mp3
├── Videos/
│   └── video1.mp4
└── MediaHub/
    └── Downloads/
        ├── downloaded1.mp3
        └── downloaded2.mp4
```

### Database Metadata Model

```text
Media Metadata Entity
├── id (Primary Key)
├── path (Filesystem URI)
├── title
├── artist
├── album
├── genre
├── duration
├── mediaType (Audio / Video)
├── artwork (Path / Cache Key)
└── createdAt / lastPlayed
```

> [!WARNING]
> Large media files are **never** stored directly inside the SQLite database. Only metadata references and file paths are persisted.

---

## 🎯 MVP Scope

### 🟢 Included in MVP
* Local media scanning & indexing
* Music & Video libraries with Search, Filter, Sort
* Mini & Full Music Players, Video Player with seek/speed
* Playlists, Favorites, and Playback History
* Download Manager (URL input, provider detection, queue, progress, completed integration)
* Drift SQLite database & local filesystem management
* 100% offline library browsing and media playback

### 🔴 Excluded from MVP (Out of Scope)
* User accounts & authentication
* Cloud storage & cloud media synchronization
* Social networking & collaborative playlists
* AI recommendations & personalized recommendation engines
* Streaming-service integration & subscription systems

---

## 🚀 Future Versions

### V2 — Cloud Metadata Synchronization
Optional cloud sync for small application metadata records (Playlists, Favorites, History, Playback Positions, Settings). Physical media remains stored locally.

### V3 — Cloud Media Synchronization
Optional media file backup and cross-device sync (Media Upload, Cloud Storage, Multi-device syncing, Conflict handling).

---

## 🛠️ Technology Stack

| Category | Technology | Role / Usage |
|---|---|---|
| **Framework** | **Flutter** | Cross-platform application framework |
| **Language** | **Dart** | Core application logic, UI, and async handling |
| **State Management** | **Riverpod** | Application state & dependency management |
| **Navigation** | **GoRouter** | Declarative route management |
| **Local Database** | **Drift + SQLite** | Type-safe persistent metadata storage |
| **Audio Engine** | **`just_audio`** | Local audio playback engine |
| **Background Audio & Focus** | **`audio_service` + `audio_session`** | System media controls, background playback & audio focus management |
| **Video Engine & PiP** | **`media_kit` + `floating`** | Native video playback engine & Android Picture-in-Picture mode |
| **Networking** | **Dio** | HTTP client for media resolution & downloading |
| **Metadata & Filesystem** | **`audio_metadata_reader` + `path_provider`** | Fast zero-overhead ID3 tag parsing & directory detection |

---

## 🏛️ Project Architecture & Structure

MediaHub follows a **layered, feature-oriented clean architecture**:

```text
Presentation Layer  ──► Application Layer ──► Domain Layer ──► Data Layer ──► Infrastructure
(Pages/Widgets/UI)      (Use Cases/Notifiers) (Entities/Rules) (Repositories) (SQLite/Filesystem)
```

```text
MediaHub/
├── AGENTS.md                   # AI Agent instructions & engineering rules
├── README.md                   # Main project documentation
├── docs/                       # Comprehensive technical documentation
│   ├── PROJECT.md              # Project specification
│   ├── REQUIREMENTS.md         # Functional and non-functional requirements
│   ├── ARCHITECTURE.md         # System architecture & layers
│   ├── TECH_STACK.md           # Technologies and package selection
│   ├── UI_DESIGN.md            # UI design system and screens
│   ├── DEVELOPMENT_PHASES.md   # Step-by-step roadmap
│   └── ACCEPTANCE_CRITERIA.md  # Acceptance criteria & test cases
├── lib/
│   ├── app/                    # App configuration, routes, theme
│   ├── core/                   # Shared utilities, constants, errors
│   ├── data/                   # Drift database, DAOs, repositories
│   ├── domain/                 # Core domain models and entities
│   ├── features/               # Feature modules
│   │   ├── library/            # Media library & scanner
│   │   ├── downloads/          # Download manager & provider system
│   │   ├── music/              # Music player & mini player
│   │   ├── video/              # Video player & fullscreen view
│   │   ├── playlists/          # Playlist management
│   │   ├── favorites/          # Favorites subsystem
│   │   ├── history/            # History & continue watching
│   │   └── settings/           # App settings & scanner config
│   └── main.dart               # Entry point
└── pubspec.yaml                # Dependencies & configuration
```

---

## 💡 Development Philosophy

* 🔒 **Local-First**: Core media functionality does not depend on internet access or remote servers.
* 🧱 **Modular**: Clear separation of concerns between Downloaders, Library, Players, and Database.
* 🛠️ **Maintainable & Testable**: Decoupled business logic isolated from UI widgets.
* ⚡ **Performant**: Efficient lazy loading, asynchronous isolates, and cached artwork rendering.
* 🛡️ **Reliable**: Graceful handling of missing files, invalid paths, and network interruptions.

---

## 💻 Development Commands

```bash
# Verify Flutter installation
flutter --version

# Fetch project dependencies
flutter pub get

# Run application in development mode
flutter run

# Execute static code analysis
flutter analyze

# Run test suite
flutter test

# Format Dart codebase
dart format .
```

---

## 🗺️ Development Roadmap

```text
Phase 0: Project Setup ──► Phase 1: Local Database ──► Phase 2: Media Scanner
                                                               │
Phase 5: Video Player ◄── Phase 4: Music Player ◄── Phase 3: Media Library
     │
     ▼
Phase 6: Download Manager ──► Phase 7: Download Integration ──► Phase 8: UI/UX Refinement
                                                                        │
Phase 10: MVP Release ◄────────────────── Phase 9: Testing & Optimization ┘
```

---

## 📚 Documentation Index

| Document | Description / Purpose |
|---|---|
| 📑 [AGENTS.md](AGENTS.md) | AI Agent development rules, architectural boundaries, and constraints |
| 📑 [PROJECT.md](docs/PROJECT.md) | In-depth product specification and problem definition |
| 📑 [REQUIREMENTS.md](docs/REQUIREMENTS.md) | Functional requirements (FR-01 to FR-80+) and system rules |
| 📑 [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Detailed layer architecture, data flow diagrams, and state management |
| 📑 [TECH_STACK.md](docs/TECH_STACK.md) | Full technical stack, package justifications, and system dependencies |
| 📑 [UI_DESIGN.md](docs/UI_DESIGN.md) | UI design system, color tokens, layout wireframes, and screen drafts |
| 📑 [DEVELOPMENT_PHASES.md](docs/DEVELOPMENT_PHASES.md) | Step-by-step roadmap from Phase 0 to Phase 20+ |
| 📑 [ACCEPTANCE_CRITERIA.md](docs/ACCEPTANCE_CRITERIA.md) | Feature acceptance criteria, edge cases, and testing verification |

---

## 📊 Current Status & Portfolio Value

> [!TIP]
> **Portfolio Project Value**: MediaHub demonstrates complete system integration across mobile app development, multimedia playback engines, local databases, file I/O operations, network handling, clean architecture, and background processing.

* **Status**: MVP Development
* **Target Platforms**: Android & Desktop
* **Backend**: None (100% Local-First)

---

<div align="center">

> **Core Principle**: Acquire, organize, manage, and play personal media from one centralized application.

</div>

---

> [!WARNING]
> **Disclaimer**: This project was developed strictly for educational purposes and as a proof-of-concept for a university thesis. It demonstrates complex local-first architecture, UI/UX design, and networking principles. It is **not** intended for commercial use or copyright infringement.
