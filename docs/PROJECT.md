<div align="center">

# 📑 MediaHub — Project Specification

[![Document Version](https://img.shields.io/badge/Doc_Type-Specification-00599C?style=for-the-badge)](docs/PROJECT.md)
[![Status](https://img.shields.io/badge/Status-MVP_Definition-2E7D32?style=for-the-badge)]()
[![Architecture](https://img.shields.io/badge/Architecture-Local--First-FF6F00?style=for-the-badge)](docs/ARCHITECTURE.md)

---

**Detailed product specification, scope boundaries, core architecture workflows, and target objectives for the MediaHub local-first multimedia platform.**

</div>

---

## 📑 Table of Contents

- [1. Project Overview](#1-project-overview)
- [2. Problem Statement](#2-problem-statement)
- [3. Proposed Solution](#3-proposed-solution)
- [4. Project Vision](#4-project-vision)
- [5. Target Users](#5-target-users)
- [6. Core Product Modules](#6-core-product-modules)
- [7. Media Types](#7-media-types)
- [8. Media Acquisition](#8-media-acquisition)
- [9. Local Media Discovery](#9-local-media-discovery)
- [10. Media Metadata](#10-media-metadata)
- [11. Storage Architecture](#11-storage-architecture)
- [12. Local-First Principle](#12-local-first-principle)
- [13. MVP Scope](#13-mvp-scope)
- [14. MVP Exclusions](#14-mvp-exclusions)
- [15. V2 — Cloud Metadata Synchronization](#15-v2--cloud-metadata-synchronization)
- [16. V3 — Cloud Media Synchronization](#16-v3--cloud-media-synchronization)
- [17. User Experience](#17-user-experience)
- [18. Music Playback Experience](#18-music-playback-experience)
- [19. Video Playback Experience](#19-video-playback-experience)
- [20. Download Experience](#20-download-experience)
- [21. Technical Objectives](#21-technical-objectives)
- [22. Architecture Principles](#22-architecture-principles)
- [23. Core Data Flow](#23-core-data-flow)
- [24. Portfolio Objective](#24-portfolio-objective)
- [25. Success Criteria](#25-success-criteria)
- [26. Final Project Principle](#26-final-project-principle)

---

## 1. Project Overview

MediaHub is a local-first multimedia application designed to centralize the acquisition, organization, management, and playback of personal music and video content.

Instead of relying on separate applications for downloading, organizing, and consuming media, MediaHub provides a unified multimedia library where users can manage and play their locally stored audio and video files.

The application combines:
- 📥 Media downloading
- 📚 Local media management
- 🎵 Music playback
- 🎬 Video playback
- 📑 Playlist management
- ❤️ Favorites
- ⏱️ Playback history

---

## 2. Problem Statement

Users commonly rely on multiple applications to manage their media:
- One application to download media.
- A file manager to locate downloaded files.
- A music player for audio content.
- A video player for videos.
- Another app for playlists or favorites.

This fragmented workflow makes personal media difficult to organize and manage. MediaHub solves this by unifying these capabilities into a single application.

---

## 3. Proposed Solution

MediaHub provides a centralized local-first environment for acquiring, organizing, managing, and playing personal media.

### Primary Downloader Workflow

```text
Media Source ──► Download Manager ──► Local File ──► Media Scanner ──► Media Library ──► Players
```

### Local Media Discovery Workflow

```text
Existing Local Files ──► Media Scanner ──► Media Library ──► Music Player / Video Player
```

> [!NOTE]
> Users do not have to download media through MediaHub for it to appear. If a supported file exists on the device filesystem, MediaHub discovers and indexes it automatically.

---

## 4. Project Vision

The long-term vision of MediaHub is to become a complete media ecosystem:
1. Acquire media.
2. Store media locally.
3. Automatically organize media.
4. Search and browse collections.
5. Play music.
6. Watch videos.
7. Create playlists.
8. Manage favorites.
9. Continue previously played media.
10. Eventually synchronize across devices.

---

## 5. Target Users

MediaHub is designed for individual users who maintain personal collections of Music, Videos, Downloaded files, and Playlists.

> [!IMPORTANT]
> The MVP is designed for a single-user experience and does not require user accounts, teacher/admin roles, social profiles, or cloud services.

---

## 6. Core Product Modules

| Module | Core Responsibility | Key Capabilities |
|---|---|---|
| 📚 **Media Library** | Central media hub | Local indexing, Music/Video views, Search, Filter, Sort, Favorites |
| 📥 **Download Manager** | Media acquisition | URL input, validation, provider detection, task queue, state handling |
| 🎵 **Music Player** | Audio playback | Play/Pause/Seek, Queue, Shuffle, Repeat, Mini Player, Background audio |
| 🎬 **Video Player** | Video playback | Play/Pause/Seek, Fullscreen, Playback speed, Resume position |
| 📑 **Playlist Manager** | Media organization | Custom playlists, add/remove tracks, reorder, persistent storage |
| ❤️ **Favorites** | User bookmarks | Favorite music & videos, persistent SQLite storage |
| ⏱️ **Playback History** | Activity tracking | Recently played, continue watching, resume positions |
| ⚙️ **Settings** | App preferences | Media scan directories, download path, theme mode |

---

## 7. Media Types

### Audio Formats
* MP3, M4A, WAV, FLAC, AAC, OGG (supported by audio player engine)

### Video Formats
* MP4, MKV, WebM, MOV, AVI (supported by video player engine)

---

## 8. Media Acquisition

MediaHub uses a provider-based downloader architecture:

```text
URL ──► Provider Detector ──► Provider ──► Media Resolver ──► Download Manager ──► Local File
```

> [!NOTE]
> The Download Manager, Media Library, and Players are strictly separated. Adding support for new online sources requires no modifications to the library or player modules.

---

## 9. Local Media Discovery

The Media Scanner discovers supported media files from configured device storage paths (e.g., `Music/`, `Videos/`, `MediaHub/Downloads/`).

---

## 10. Media Metadata

MediaHub extracts ID3 and video tags into structured metadata:

```text
Media Metadata Schema
├── ID
├── File Path
├── Title (Fallback: Filename if tag missing)
├── Artist
├── Album
├── Genre
├── Duration
├── Media Type (Audio / Video)
├── Artwork / Thumbnail
├── File Size
├── Date Added
└── Last Played
```

---

## 11. Storage Architecture

```text
Filesystem Storage                 SQLite Database (Drift)
├── Audio Files (.mp3, .flac)      ├── Media Metadata
└── Video Files (.mp4, .mkv)       ├── Playlists & Items
                                   ├── Favorites & History
                                   ├── Playback Positions
                                   └── Download Tasks
```

> [!WARNING]
> Large media files are stored on disk, never directly inside SQLite database columns.

---

## 12. Local-First Principle

> [!IMPORTANT]
> All core media features (Browsing, Search, Music & Video playback, Playlists, Favorites, History) must function 100% offline without network access.

---

## 13. MVP Scope

### Included Features
- Local media scanning & indexing
- Music & Video library tabs with Search, Filter, Sort
- Mini & Full Music Players, Video Player with seek/speed
- Playlists, Favorites, Playback History, Recently Played
- Download Manager (URL input, provider detection, queue, progress, integration)
- Local SQLite database & filesystem management

---

## 14. MVP Exclusions

- User accounts & authentication
- Cloud storage & media synchronization
- Social networking & collaborative playlists
- AI recommendation engines
- Subscription & streaming service integrations

---

## 15. V2 — Cloud Metadata Synchronization

Future cloud metadata synchronization:

```text
Device A ──► Cloud Metadata ──► Device B
```

Syncs Playlists, Favorites, Playback history, Positions, Settings, and Metadata while physical files remain local.

---

## 16. V3 — Cloud Media Synchronization

Future media synchronization:

```text
Device A ──(Upload)──► Cloud Storage ──(Download)──► Device B
```

---

## 17. User Experience

Navigation structure: `Home`, `Library`, `Downloads`, `Playlists`, `Settings`.

### Persistent Mini Player Concept
```text
┌───────────────────────────────────────────────┐
│ [Artwork] Song Title      ◀   ▶   ►   │
└───────────────────────────────────────────────┘
```

---

## 18. Music Playback Experience

Full player view includes Artwork, Title, Artist, Progress Bar, Timers, Previous, Play/Pause, Next, Shuffle, Repeat, and system notification controls.

---

## 19. Video Playback Experience

Prioritizes video content with Play/Pause, Seek bar, Fullscreen mode, Speed controls (`0.5x` - `2.0x`), and resume position tracking.

---

## 20. Download Experience

Mock Download UI State:
```text
┌───────────────────────────────────────────────┐
│ Downloads                                     │
├───────────────────────────────────────────────┤
│ Paste Media URL:                              │
│ [ https://example.com/media.mp3 ]             │
│ [ Start Download ]                            │
├───────────────────────────────────────────────┤
│ Active Downloads:                             │
│ Track Title 1   [████████████░░] 75%         │
│ Video Title 2   [██████████████] 100% Done    │
└───────────────────────────────────────────────┘
```

Supported Task States: `Queued`, `Resolving`, `Downloading`, `Paused`, `Completed`, `Failed`, `Cancelled`.

---

## 21. Technical Objectives

Demonstrates Flutter cross-platform architecture, Dart async & isolates, Riverpod state management, Drift SQLite persistence, filesystem management, multimedia engines, Dio networking, and unit/widget testing.

---

## 22. Architecture Principles

- **Separation of Concerns**: Isolated modules for Download, Library, Player, DB, FS.
- **Low Coupling & High Cohesion**: Feature-oriented structure.
- **Dependency Inversion**: Core domain logic remains decoupled from UI.
- **Local-First & Extensible**: Designed for offline reliability with clean extension points.

---

## 23. Core Data Flow

### Local Media Flow
```text
Device Storage ──► Scanner ──► Metadata Extraction ──► SQLite ──► Library ──► Players
```

### Downloaded Media Flow
```text
Supported URL ──► Provider ──► Downloader ──► Disk File ──► Scanner ──► SQLite ──► Library ──► Players
```

---

## 24. Portfolio Objective

MediaHub proves ability to engineer a complete, multi-subsystem, production-grade application combining audio, video, networking, database persistence, and local file I/O.

---

## 25. Success Criteria Checklist

- [x] Launch app & initialize local database.
- [x] Scan local storage directories.
- [x] Browse music & video libraries.
- [x] Search media by title, artist, album, genre.
- [x] Play local audio tracks with queue & background audio.
- [x] Play local video clips with seek & speed control.
- [x] Create and manage custom playlists.
- [x] Favorite audio & video media.
- [x] Record playback history and position.
- [x] Validate URLs & download supported media.
- [x] Auto-index downloaded media into local library.
- [x] Work 100% offline for local media tasks.

---

## 26. Final Project Principle

<div align="center">

> **Acquire, organize, manage, and play personal media from one centralized application.**

</div>
