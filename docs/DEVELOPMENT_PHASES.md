<div align="center">

# 🗺️ MediaHub — Development Roadmap & Implementation Phases

[![Document Version](https://img.shields.io/badge/Doc_Type-Roadmap-00599C?style=for-the-badge)](docs/DEVELOPMENT_PHASES.md)
[![Total Phases](https://img.shields.io/badge/Phases-0_to_30-2E7D32?style=for-the-badge)]()
[![Status](https://img.shields.io/badge/Status-Active_Roadmap-FF6F00?style=for-the-badge)]()

---

**Step-by-step incremental development roadmap for building MediaHub from Phase 0 (Project Setup) through Phase 30 (Post-MVP Extensions).**

</div>

---

## 📑 Table of Contents

- [1. Overview & Strategy](#1-overview--strategy)
- [2. Roadmap Summary Matrix](#2-roadmap-summary-matrix)
- [3. Phase 0 — Project Foundation](#3-phase-0--project-foundation)
- [4. Phase 1 — Local Database Infrastructure](#4-phase-1--local-database-infrastructure)
- [5. Phase 2 — Media Scanner Subsystem](#5-phase-2--media-scanner-subsystem)
- [6. Phase 3 — Media Library UI & Logic](#6-phase-3--media-library-ui--logic)
- [7. Phase 4 — Music Player Engine](#7-phase-4--music-player-engine)
- [8. Phase 5 — Video Player Engine](#8-phase-5--video-player-engine)
- [9. Phase 6 — Playlist Subsystem](#9-phase-6--playlist-subsystem)
- [10. Phase 7 — Favorites Subsystem](#10-phase-7--favorites-subsystem)
- [11. Phase 8 — Playback History & Resume](#11-phase-8--playback-history--resume)
- [12. Phase 9 — Search, Filter & Sort](#12-phase-9--search-filter--sort)
- [13. Phase 10 — Download Manager Engine](#13-phase-10--download-manager-engine)
- [14. Phase 11 — Media Source Providers](#14-phase-11--media-source-providers)
- [15. Phase 12 — Download-to-Library Ingestion](#15-phase-12--download-to-library-ingestion)
- [16. Phase 13 — Settings & Directory Scanner Config](#16-phase-13--settings--directory-scanner-config)
- [17. Phase 14 — Home Screen Aggregator](#17-phase-14--home-screen-aggregator)
- [18. Phase 15 — UI/UX Polish & Design Tokens](#18-phase-15--uiux-polish--design-tokens)
- [19. Phase 16 — Responsive & Adaptive Layouts](#19-phase-16--responsive--adaptive-layouts)
- [20. Phase 17 — Robust Error & Empty States](#20-phase-17--robust-error--empty-states)
- [21. Phase 18 — Unit & Widget Testing](#21-phase-18--unit--widget-testing)
- [22. Phase 19 — Integration Testing](#22-phase-19--integration-testing)
- [23. Phase 20 — Edge Case Resilience](#23-phase-20--edge-case-resilience)
- [24. Phase 21 — Performance & Resource Tuning](#24-phase-21--performance--resource-tuning)
- [25. Phase 22 — Security & Privacy Audit](#25-phase-22--security--privacy-audit)
- [26. Phase 23 — Documentation Polish](#26-phase-23--documentation-polish)
- [27. Phase 24 — MVP Functional Verification](#27-phase-24--mvp-functional-verification)
- [28. Phase 25 — MVP Release Build](#28-phase-25--mvp-release-build)
- [29. Phase 26 — Portfolio & Demo Presentation](#29-phase-26--portfolio--demo-presentation)
- [30. Phase 27 — Post-MVP Features (V1.5)](#30-phase-27--post-mvp-features-v15)
- [31. Phase 28 — Cloud Metadata Sync (V2)](#31-phase-28--cloud-metadata-sync-v2)
- [32. Phase 29 — Multi-Device Media Sync (V3)](#32-phase-29--multi-device-media-sync-v3)
- [33. Phase 30 — Advanced Media Management (V4)](#33-phase-30--advanced-media-management-v4)
- [34. Development Priorities & Build Order](#34-development-priorities--build-order)
- [35. Milestones & Definition of Completion](#35-milestones--definition-of-completion)

---

## 1. Overview & Strategy

MediaHub is constructed incrementally from foundational storage layers up to presentation players and download engines.

> [!IMPORTANT]
> **Incremental Execution Rule**: Each phase must be fully implemented, analyzed (`flutter analyze`), and tested (`flutter test`) before proceeding to the next phase.

---

## 2. Roadmap Summary Matrix

```text
Phase 0-2 (Foundations) ──► Phase 3-5 (Library & Players) ──► Phase 6-9 (Organization)
                                                                     │
Phase 15-20 (Polish/Testing) ◄── Phase 10-14 (Downloader) ───────────┘
         │
         ▼
Phase 21-26 (MVP Release & Portfolio) ──► Phase 27-30 (V2/V3 Cloud Roadmap)
```

---

## 3. Phase 0 — Project Foundation

- [ ] Create Flutter project & configure `pubspec.yaml`.
- [ ] Establish folder structure according to `AGENTS.md`.
- [ ] Setup Riverpod state management & GoRouter routing shell.
- [ ] Define global design tokens (`app_theme.dart`, `app_colors.dart`).

---

## 4. Phase 1 — Local Database Infrastructure

- [ ] Setup Drift SQLite database & entities (`MediaItems`, `Playlists`, `PlaylistItems`, `Favorites`, `History`, `DownloadTasks`, `Settings`).
- [ ] Implement DAOs with type-safe reactive streams.
- [ ] Add unit tests for SQLite CRUD operations.

---

## 5. Phase 2 — Media Scanner Subsystem

- [ ] Implement `MediaScannerService` for directory traversal.
- [ ] Extract ID3 & metadata tags asynchronously.
- [ ] Upsert discovered records into SQLite database.

---

## 6. Phase 3 — Media Library UI & Logic

- [ ] Build Music & Video library tabs.
- [ ] Connect Riverpod providers to query Drift SQLite data.
- [ ] Render media cards, list tiles, and album artwork placeholders.

---

## 7. Phase 4 — Music Player Engine

- [ ] Integrate `just_audio` engine with `audio_service`.
- [ ] Build persistent Mini Player & Full Player overlay views.
- [ ] Implement Queue management, Play/Pause, Seek, Skip, Shuffle, Repeat.

---

## 8. Phase 5 — Video Player Engine

- [ ] Integrate `media_kit` native video playback engine.
- [ ] Implement video controls: Play/Pause, Seek bar, Fullscreen toggle, Playback speed (`0.5x`-`2.0x`).
- [ ] Save last playback position marker to SQLite on pause/exit.

---

## 9. Phase 6 — Playlist Subsystem

- [ ] Implement Playlist repository & CRUD operations.
- [ ] Create UI for Create, Rename, Delete playlists, Add/Remove tracks, Reorder items.
- [ ] *Verify playlist item removal does NOT delete disk files.*

---

## 10. Phase 7 — Favorites Subsystem

- [ ] Bookmark tracks & video clips.
- [ ] Toggle favorite status with reactive SQLite updates.
- [ ] Build Favorites collection screen.

---

## 11. Phase 8 — Playback History & Resume

- [ ] Record playback activity timestamps into SQLite.
- [ ] Display "Recently Played" tracks & "Continue Watching" video cards.

---

## 12. Phase 9 — Search, Filter & Sort

- [ ] Implement real-time metadata search by Title, Artist, Album, Genre.
- [ ] Implement sorting by Date Added, Title, Duration, Last Played.

---

## 13. Phase 10 — Download Manager Engine

- [ ] Build `DownloadManager` task state machine (`Queued`, `Resolving`, `Downloading`, `Paused`, `Completed`, `Failed`, `Cancelled`).
- [ ] Integrate Dio for background download HTTP streams with progress callbacks.

---

## 14. Phase 11 — Media Source Providers

- [ ] Create provider abstraction contract (`MediaSourceProvider`).
- [ ] Build URL validation, detector, and media metadata resolver.

---

## 15. Phase 12 — Download-to-Library Ingestion

```text
Download Completed ──► Save File ──► Scanner Pass ──► Metadata Extractor ──► Upsert SQLite ──► Library UI
```

---

## 16. Phase 13 — Settings & Directory Scanner Config

- [ ] Settings screen for configuring scan paths, download folder, app theme mode.

---

## 17. Phase 14 — Home Screen Aggregator

- [ ] Combine Recently Played, Continue Watching, Quick Actions, and Featured media into Home view.

---

## 18. Phase 15 — UI/UX Polish & Design Tokens
## 19. Phase 16 — Responsive & Adaptive Layouts
## 20. Phase 17 — Robust Error & Empty States
## 21. Phase 18 — Unit & Widget Testing
## 22. Phase 19 — Integration Testing
## 23. Phase 20 — Edge Case Resilience
## 24. Phase 21 — Performance & Resource Tuning
## 25. Phase 22 — Security & Privacy Audit
## 26. Phase 23 — Documentation Polish

---

## 27. Phase 24 — MVP Functional Verification Checklist

- [ ] Local music discovery works.
- [ ] Local video discovery works.
- [ ] Search, filter, sort function clean.
- [ ] Audio playback (seek, queue, shuffle, repeat, background) works.
- [ ] Video playback (seek, speed, fullscreen, resume position) works.
- [ ] Playlists, Favorites, History persist after app restart.
- [ ] URL download, task queue, progress stream, cancellation work.
- [ ] Downloaded media auto-indexes into library.
- [ ] 100% offline functionality for local media.

---

## 28. Phase 25 — MVP Release Build & 29. Phase 26 — Portfolio Presentation

Execute `flutter analyze` & `flutter test`, compile final APK/Desktop binaries, record demo video, finalize write-ups.

---

## 30. Phase 27 to 33. Phase 30 — Future V2/V3/V4 Roadmap

- **V2 (Phase 28)**: Cloud Metadata Sync (Playlists, Favorites, History).
- **V3 (Phase 29)**: Cloud Media Sync (File backup & cross-device transfer).
- **V4 (Phase 30)**: Smart Media Features (AI organization, smart playlists, duplicate cleanup).

---

## 34. Development Priorities & Build Order

```text
P0 (Critical): Foundation ──► SQLite ──► Scanner ──► Library ──► Music/Video Players
P1 (Important): Playlists ──► Favorites ──► History ──► Download Manager ──► Search
P2 (Polish): Theme Design Tokens ──► Responsive Layouts ──► Unit/Widget Tests
P3 (Future): Cloud Metadata Sync ──► Multi-device Sync
```

---

## 35. Milestones & Definition of Completion

<div align="center">

> **Definition of Complete**: Implemented + Connected + Tested + Error/Empty states handled + `flutter analyze` & `flutter test` pass clean.

</div>
