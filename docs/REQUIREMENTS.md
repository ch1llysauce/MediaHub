<div align="center">

# 📋 MediaHub — Requirements Specification

[![Document Version](https://img.shields.io/badge/Doc_Type-Requirements-00599C?style=for-the-badge)](docs/REQUIREMENTS.md)
[![Scope](https://img.shields.io/badge/Scope-MVP_Functional_%26_NFR-2E7D32?style=for-the-badge)]()
[![Status](https://img.shields.io/badge/Status-Active_Spec-FF6F00?style=for-the-badge)]()

---

**Complete functional (FR-01 to FR-84) and non-functional (NFR-01 to NFR-10) requirements specification for the MediaHub local-first multimedia application.**

</div>

---

## 📑 Table of Contents

- [1. Purpose](#1-purpose)
- [2. User Requirements](#2-user-requirements)
- [3. Functional Requirements — Application & Library](#3-functional-requirements--application--library)
  - [FR-01 to FR-09](#fr-01--application-startup)
- [4. Functional Requirements — Music Player](#4-functional-requirements--music-player)
  - [FR-10 to FR-23](#fr-10--play-music)
- [5. Functional Requirements — Video Player](#5-functional-requirements--video-player)
  - [FR-24 to FR-31](#fr-24--play-video)
- [6. Functional Requirements — Playlists](#6-functional-requirements--playlists)
  - [FR-32 to FR-38](#fr-32--create-playlist)
- [7. Functional Requirements — Favorites](#7-functional-requirements--favorites)
  - [FR-39 to FR-42](#fr-39--add-favorite)
- [8. Functional Requirements — Playback History](#8-functional-requirements--playback-history)
  - [FR-43 to FR-46](#fr-43--record-playback)
- [9. Functional Requirements — Download Manager](#9-functional-requirements--download-manager)
  - [FR-47 to FR-60](#fr-47--url-input)
- [10. Functional Requirements — Download-to-Library Integration](#10-functional-requirements--download-to-library-integration)
  - [FR-61 to FR-63](#fr-61--completed-download-detection)
- [11. Functional Requirements — Filesystem](#11-functional-requirements--filesystem)
  - [FR-64 to FR-67](#fr-64--file-access)
- [12. Functional Requirements — Database](#12-functional-requirements--database)
  - [FR-68 to FR-75](#fr-68--local-persistence)
- [13. Functional Requirements — Settings](#13-functional-requirements--settings)
  - [FR-76 to FR-79](#fr-76--media-directories)
- [14. Functional Requirements — UI & Navigation](#14-functional-requirements--ui--navigation)
  - [FR-80 to FR-84](#fr-80--navigation)
- [15. Non-Functional Requirements](#15-non-functional-requirements)
  - [NFR-01 to NFR-10](#nfr-01--performance)
- [16. MVP Scope Boundary](#16-mvp-scope-boundary)
- [17. MVP Completion Criteria](#17-mvp-completion-criteria)
- [18. Engineering Quality Criteria](#18-engineering-quality-criteria)
- [19. Final Requirement Principle](#19-final-requirement-principle)

---

## 1. Purpose

This document defines the functional and non-functional requirements of MediaHub.

MediaHub is a local-first multimedia application that combines:
- Media downloading
- Local media management
- Music playback
- Video playback
- Playlist management
- Favorites
- Playback history

The requirements in this document define the expected behavior of the MVP.

---

## 2. User Requirements

The user should be able to:
1. Scan their device for supported media files.
2. Browse their music collection.
3. Browse their video collection.
4. Search their media.
5. Filter and sort media.
6. Play music.
7. Watch videos.
8. Create and manage playlists.
9. Favorite media.
10. View recently played media.
11. Resume previously played videos.
12. Enter supported media URLs.
13. Manage downloads.
14. View download progress.
15. Access completed downloads through the Media Library.
16. Use core library and playback features without internet access.

---

## 3. Functional Requirements — Application & Library

### FR-01 — Application Startup
The application shall:
- Launch successfully and initialize required local services & Drift SQLite database.
- Load application settings and restore relevant application state.
- Navigate to the appropriate initial screen.
- *Failure to initialize a non-critical component should not cause the entire application to crash.*

---

### FR-02 — Local Media Scanning
The application shall scan configured directories for supported audio and video files.
- Detect supported audio & video files while ignoring unsupported files.
- Detect newly added and removed files.
- Handle inaccessible directories safely without blocking the main UI.

---

### FR-03 — Media Indexing
Discovered media shall be indexed in the local database storing available metadata:
- File path, Title, Artist, Album, Genre, Duration, File size, Media type, Artwork, Date added.
- *Missing metadata shall not prevent the media from being indexed.*

---

### FR-04 — Media Library
Provides a centralized Media Library supporting Music browsing, Video browsing, Search, Filtering, Sorting, Recently added, Recently played, and Favorites.
- Retrieves metadata from local SQLite rather than rescanning the filesystem during normal browsing.

---

### FR-05 — Music Library
Displays supported audio files with Artwork, Title, Artist, Album, and Duration. Selecting an item allows playing it.

---

### FR-06 — Video Library
Displays supported video files with Thumbnail, Title, Duration, and File info. Selecting a video opens the Video Player.

---

### FR-07 — Search
Allows users to search local media by Title, Artist, Album, and Genre efficiently for large collections.

---

### FR-08 — Filtering
Supports media filtering by Music, Videos, Favorites, Artists, Albums, Genres, Recently added, and Recently played.

---

### FR-09 — Sorting
Supports sorting media by Title, Artist, Album, Date added, Recently played, and Duration.

---

## 4. Music Player Requirements

| ID | Requirement Name | Description |
|---|---|---|
| **FR-10** | Play Music | Shall play supported local audio files. |
| **FR-11** | Pause Music | Users shall be able to pause currently playing audio. |
| **FR-12** | Resume Music | Users shall be able to resume paused audio. |
| **FR-13** | Seek Music | Users shall be able to seek to a different playback position. |
| **FR-14** | Previous Track | Shall allow users to return to the previous track. |
| **FR-15** | Next Track | Shall allow users to skip to the next track. |
| **FR-16** | Queue | Audio queue supporting Add, Remove, Reorder, Clear, and Play queued tracks. |
| **FR-17** | Shuffle | Shall support shuffle playback mode. |
| **FR-18** | Repeat | Modes: `No Repeat`, `Repeat All`, `Repeat One`. |
| **FR-19** | Playback Progress | Displays current position, total duration, and progress bar. |
| **FR-20** | Mini Player | Persistent mini player displaying artwork, title, basic controls, and state. |
| **FR-21** | Full Player | View displaying Artwork, Title, Artist, Progress, Play/Pause, Skip, Shuffle, Repeat. |
| **FR-22** | Background Playback | Audio playback continues in background where platform permits. |
| **FR-23** | System Media Controls | System notification/lock-screen media controls where supported. |

---

## 5. Video Player Requirements

| ID | Requirement Name | Description |
|---|---|---|
| **FR-24** | Play Video | Shall play supported local video files. |
| **FR-25** | Pause Video | Users shall be able to pause video playback. |
| **FR-26** | Resume Video | Users shall be able to resume paused video playback. |
| **FR-27** | Seek Video | Users shall be able to seek to different positions in the video. |
| **FR-28** | Fullscreen | Video player shall support fullscreen playback mode. |
| **FR-29** | Playback Speed | Multiple speeds supported (`0.5x`, `0.75x`, `1.0x`, `1.25x`, `1.5x`, `2.0x`). |
| **FR-30** | Playback Position | Remembers the last playback position of video files. |
| **FR-31** | Continue Watching | Users can resume videos from their previous playback position. |

---

## 6. Playlist Requirements

- **FR-32 — Create Playlist**: Create custom playlists with Unique ID, Name, and Creation Date.
- **FR-33 — Rename Playlist**: Rename existing playlists.
- **FR-34 — Delete Playlist**: Delete playlists without deleting physical media files on disk.
- **FR-35 — Add Media to Playlist**: Add supported audio/video files to playlists.
- **FR-36 — Remove Media from Playlist**: Remove items from playlists without deleting physical files.
- **FR-37 — Reorder Playlist**: Reorder items within playlists.
- **FR-38 — Play Playlist**: Start audio/video playback from a playlist.

---

## 7. Favorites Requirements

- **FR-39 — Add Favorite**: Mark media items as favorites.
- **FR-40 — Remove Favorite**: Remove media items from favorites.
- **FR-41 — Favorites Persistence**: Favorite state persists after app restart.
- **FR-42 — Favorites Library**: Browse favorited music and videos in a dedicated section.

---

## 8. Playback History Requirements

- **FR-43 — Record Playback**: Record relevant playback activity and timestamps.
- **FR-44 — Recently Played**: Provide quick access to recently played media.
- **FR-45 — Playback Position**: Save precise playback position markers.
- **FR-46 — History Persistence**: History survives app restarts.

---

## 9. Download Manager Requirements

- **FR-47 — URL Input**: Enter supported online media URLs.
- **FR-48 — URL Validation**: Validate input URLs with clear error feedback.
- **FR-49 — Provider Detection**: Modular provider system detects associated media providers.
- **FR-50 — Media Resolution**: Resolves Title, Thumbnail, Duration, and Formats prior to downloading.
- **FR-51 — Task Creation**: Converts resolved media into task records (ID, URL, Title, Status, Progress).
- **FR-52 — Download Queue**: Manages Active, Queued, Completed, and Failed tasks.
- **FR-53 — Download Progress**: Displays Percentage, Downloaded/Total Size, Speed, and ETA.
- **FR-54 — Download States**: Enums: `Queued`, `Resolving`, `Downloading`, `Paused`, `Completed`, `Failed`, `Cancelled`.
- **FR-55 — Pause Download**: Pause active downloads where supported.
- **FR-56 — Resume Download**: Resume paused downloads where supported.
- **FR-57 — Cancel Download**: Cancel active or queued tasks.
- **FR-58 — Retry Download**: Retry failed tasks.
- **FR-59 — Download Destination**: Save completed media to configured storage path.
- **FR-60 — Error Handling**: Gracefully handle Network, Invalid URL, Storage, and Permission errors.

---

## 10. Download-to-Library Integration

- **FR-61 — Completed Download Detection**: Recognized as local media files upon completion.
- **FR-62 — Media Indexing After Download**: Auto-indexes downloaded files into local library via Scanner:

```text
Download ──► Local File ──► Scanner ──► Metadata Extraction ──► Database ──► Media Library
```

- **FR-63 — Duplicate Handling**: Avoid creating duplicate database records when files are rescanned.

---

## 11. Filesystem Requirements

- **FR-64 — File Access**: Access files using standard platform filesystem APIs.
- **FR-65 — Missing Files**: Handle missing media gracefully without crashing.
- **FR-66 — File Permission Errors**: Handle restricted or inaccessible folders safely.
- **FR-67 — Storage Information**: Display Used space, Available space, and Download directory path.

---

## 12. Database Requirements

- **FR-68 — Local Persistence**: Drift + SQLite for persistent app data.
- **FR-69 — Media Table**: Store media metadata records.
- **FR-70 — Playlist Tables**: Store playlists and playlist-media relationships.
- **FR-71 — Favorites**: Store favorite flags.
- **FR-72 — Playback History**: Store history timestamps.
- **FR-73 — Playback Positions**: Store playback seek markers.
- **FR-74 — Download Records**: Store download task states.
- **FR-75 — Settings**: Store application preferences.

---

## 13. Settings Requirements

- **FR-76 — Media Directories**: Configure folders to scan for local media.
- **FR-77 — Download Directory**: Configure preferred download destination.
- **FR-78 — Theme**: Preferences for `System`, `Light`, or `Dark` themes.
- **FR-79 — Library Rescan**: Manually trigger a media rescan.

---

## 14. UI & Navigation Requirements

- **FR-80 — Navigation**: Navigation between `Home`, `Library`, `Downloads`, `Playlists`, and `Settings`.
- **FR-81 — Loading States**: Visual feedback during scanning, resolving, and DB init.
- **FR-82 — Empty States**: Clear empty views for Library, Downloads, Playlists, and Favorites.
- **FR-83 — Error States**: User-friendly error messages explaining what happened and recovery steps.
- **FR-84 — Responsive Layout**: Adaptable layout across supported mobile and screen sizes.

---

## 15. Non-Functional Requirements

| ID | Category | Requirement Description |
|---|---|---|
| **NFR-01** | Performance | Smooth UI response during scanning, querying, loading artwork, and downloading. |
| **NFR-02** | Reliability | Handle unexpected exceptions gracefully without crashing. |
| **NFR-03** | Maintainability | Clean, modular architecture with clear feature boundaries. |
| **NFR-04** | Testability | Business logic isolated from UI widgets for unit/widget testing. |
| **NFR-05** | Offline Capability | Library, search, music/video playback, playlists, favorites function 100% offline. |
| **NFR-06** | Privacy | Local storage priority; no unauthorized cloud uploads. |
| **NFR-07** | Security | Input validation, safe filesystem path handling, secure credential management. |
| **NFR-08** | Scalability | Architecture supports future cloud sync, providers, and extensions cleanly. |
| **NFR-09** | Usability | Clear UI feedback for loading, errors, empty states, and playback state. |
| **NFR-10** | Compatibility | Android prioritized for MVP while keeping Dart code portable. |

---

## 16. MVP Scope Boundary

```text
INCLUDED IN MVP:
Local Media Scanner + Media Library + Music Player + Video Player + Playlists + Favorites + Playback History + Download Manager + Download-to-Library Integration
```

```text
EXCLUDED FROM MVP:
Cloud Storage | Cloud Sync | User Accounts | Social Features | AI Recommendations | Collaborative Playlists | Multi-user
```

---

## 17. MVP Completion Criteria

The MVP is complete when the user can:
1. Launch MediaHub & scan local storage.
2. Discover, browse, search, filter, and sort music and video files.
3. Play music (play/pause/seek, queue, shuffle, repeat, mini player, background playback).
4. Play videos (play/pause/seek, fullscreen, speed, resume position).
5. Manage playlists, favorites, and view playback history.
6. Enter supported URLs, queue downloads, track progress, retry/cancel, and auto-index downloaded files into the library.
7. Perform all core local media operations completely offline.

---

## 18. Engineering Quality Criteria

- [x] `flutter analyze` passes clean.
- [x] `flutter test` passes clean.
- [x] Core business logic covered by tests.
- [x] No unhandled fatal crashes.
- [x] Loading, Empty, and Error UI states implemented.
- [x] Stable database persistence & scanner.
- [x] Clean architecture strictly following `AGENTS.md`.

---

## 19. Final Requirement Principle

<div align="center">

> **Users should be able to acquire, organize, manage, and play their personal music and video files through one centralized local-first application.**

</div>