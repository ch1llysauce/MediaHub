<div align="center">

# 🧪 MediaHub — Acceptance Criteria & Verification Specification

[![Document Version](https://img.shields.io/badge/Doc_Type-Acceptance_Criteria-00599C?style=for-the-badge)](docs/ACCEPTANCE_CRITERIA.md)
[![Verification Standard](https://img.shields.io/badge/Standard-Given--When--Then-2E7D32?style=for-the-badge)]()
[![Status](https://img.shields.io/badge/Status-Active_Test_Matrix-FF6F00?style=for-the-badge)]()

---

**Formal test cases (AC-01 through AC-94), Given/When/Then scenarios, edge case resilience checks, and MVP Definition of Done criteria for MediaHub.**

</div>

---

## 📑 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Testing Standard](#2-testing-standard)
- [3. Application Startup](#3-application-startup)
- [4. Local Media Scanning](#4-local-media-scanning)
- [5. Media Library](#5-media-library)
- [6. Search, Filtering, and Sorting](#6-search-filtering-and-sorting)
- [7. Music Player](#7-music-player)
- [8. Video Player](#8-video-player)
- [9. Playlists](#9-playlists)
- [10. Favorites](#10-favorites)
- [11. Playback History](#11-playback-history)
- [12. Download Manager](#12-download-manager)
- [13. Download-to-Library Integration](#13-download-to-library-integration)
- [14. Filesystem](#14-filesystem)
- [15. Settings](#15-settings)
- [16. Offline Functionality](#16-offline-functionality)
- [17. UI Acceptance Criteria](#17-ui-acceptance-criteria)
- [18. Responsive UI](#18-responsive-ui)
- [19. Accessibility](#19-accessibility)
- [20. Data Integrity](#20-data-integrity)
- [21. Error Recovery](#21-error-recovery)
- [22. Performance Acceptance Criteria](#22-performance-acceptance-criteria)
- [23. Testing Acceptance Criteria](#23-testing-acceptance-criteria)
- [24. Code Quality Acceptance Criteria](#24-code-quality-acceptance-criteria)
- [25. Documentation](#25-documentation)
- [26. Security and Privacy](#26-security-and-privacy)
- [27. MVP Release Checklist](#27-mvp-release-checklist)
- [28. Definition of Done](#28-definition-of-done)

---

## 1. Purpose

This document defines the formal Acceptance Criteria for MediaHub. Every implemented feature must satisfy its corresponding acceptance criteria before being marked complete.

---

## 2. Testing Standard

Test scenarios use the **Given / When / Then** format:
- **Given**: Initial application state or environment context.
- **When**: Action or event performed by the user or system.
- **Then**: Expected system outcome, UI state change, or database assertion.

---

## 3. Application Startup

### AC-01 — Normal Application Launch
- **Given**: MediaHub is installed on a supported platform.
- **When**: The user opens the application.
- **Then**:
  - The application launches without crashing.
  - Necessary database connections & settings initialize.
  - The initial home/library screen is displayed.

---

## 4. Local Media Scanning

| ID | Title | Given | When | Then |
|---|---|---|---|---|
| **AC-02** | Initial Directory Scan | App configured with valid folder containing media | Scan runs | Audio and video files detected, metadata extracted, database populated |
| **AC-03** | Unsupported Files | Directory contains unsupported `.txt` or `.exe` files | Scan runs | Unsupported files ignored; database contains only valid media |
| **AC-04** | Missing Directory | Configured directory deleted or unmounted | Scan runs | App logs warning, displays non-fatal error, and remains fully functional |

---

## 5. Media Library

- **AC-05 — View Music Collection**: Index contains audio files ──► Open Music tab ──► Displays track list with artwork, title, artist, album, duration.
- **AC-06 — View Video Collection**: Index contains video files ──► Open Video tab ──► Displays video list with thumbnail, title, duration.
- **AC-07 — Empty Library State**: No media files exist ──► Open Library ──► Helpful empty state rendered with `[ Scan Media ]` button.

---

## 6. Search, Filtering, and Sorting

- **AC-08 — Real-time Search**: Type matching query in Search bar ──► Filtered list displays matching media instantly.
- **AC-09 — Category Filtering**: Select Music or Video filter ──► Display strictly matching media items.
- **AC-10 — Sorting Media**: Change sort option (Date Added, Title, Duration) ──► Reorders list items accurately.

---

## 7. Music Player

| ID | Test Scenario | Given | When | Then |
|---|---|---|---|---|
| **AC-11** | Play Audio Track | Audio track selected | User taps track | Audio playback begins, Mini Player renders |
| **AC-12** | Pause / Resume | Audio is playing | Tap Pause / Resume | Audio pauses/resumes cleanly without lag |
| **AC-13** | Seek Track Position | Audio is playing | User moves seek bar | Playback jumps to selected position |
| **AC-14** | Queue Management | Tracks in queue | User reorders/skips | Queue updates order, skip moves to next track |
| **AC-15** | Background Audio | Audio playing | User minimizes app | Audio continues playing, system notification displays |

---

## 8. Video Player

- **AC-16 — Play Video Clip**: Select video card ──► Video Player opens ──► Video streams cleanly.
- **AC-17 — Fullscreen Toggle**: Tap Fullscreen button ──► Video fills screen, controls auto-hide.
- **AC-18 — Adjust Playback Speed**: Select `1.5x` speed ──► Video speed updates, audio pitch remains normal.
- **AC-19 — Resume Playback Marker**: Leave video halfway ──► Re-open video ──► Resumes playback from saved offset.

---

## 9. Playlists

- **AC-20 — Create Playlist**: Enter playlist name ──► Tap Create ──► Playlist saved to SQLite DB.
- **AC-21 — Add/Remove Media**: Add track to playlist ──► Track appears in list; deleting playlist item **does NOT** delete physical disk file.
- **AC-22 — Delete Playlist**: Select Delete Playlist ──► Playlist record deleted from DB; physical media files untouched.

---

## 10. Favorites & 11. Playback History

- **AC-23 — Toggle Favorite**: Tap heart icon ──► Marked favorite in SQLite DB; persists across app reboot.
- **AC-24 — History Track Record**: Play track for >10s ──► Record added to Recently Played history view.

---

## 12. Download Manager

| ID | Test Scenario | Given | When | Then |
|---|---|---|---|---|
| **AC-25** | Valid URL Download | Valid media URL input | Tap Download | Task created, queued, resolving, downloading |
| **AC-26** | Invalid URL Input | Malformed URL input | Tap Download | Rejected with error message, no invalid task created |
| **AC-27** | Cancel Task | Active download running | Tap Cancel | Transfer stops, temporary files cleaned up safely |
| **AC-28** | Retry Task | Failed download task | Tap Retry | Task resets to Queued/Downloading state |

---

## 13. Download-to-Library Integration

- **AC-29 — Auto Ingestion**: Download finishes ──► Task marked Completed ──► File auto-scanned & displayed in Music/Video library.

---

## 14. Filesystem & 15. Settings

- **AC-30 — File Missing on Disk**: DB entry exists but physical file deleted ──► Tap item ──► Friendly "Media Unavailable" message shown; app does not crash.
- **AC-31 — Change Scan Folders**: Add new directory path in Settings ──► Folder saved ──► Scanner searches newly added folder.

---

## 16. Offline Functionality

> [!IMPORTANT]
> **100% Offline Capability**: Browsing library, searching, music playback, video playback, playlist editing, and history tracking **MUST** work without active internet access.

---

## 17. UI & 18. Responsive UI & 19. Accessibility

Adaptable layout across phone, tablet, and desktop viewports. Contrast ratios satisfy WCAG AA standards. Primary touch targets >= `48x48dp`.

---

## 20. Data Integrity & 21. Error Recovery

Orphaned database records handled safely. Database transactions rollback safely on error. Non-critical error in download manager does not interrupt active audio playback.

---

## 22. Performance & 23. Testing & 24. Code Quality

- `flutter analyze` passes clean with zero errors.
- `flutter test` executes full test suite clean.
- `dart format .` complies with Dart style guidelines.

---

## 25. Documentation & 26. Security / Privacy

Local-first privacy maintained. Secrets and API keys excluded from Git repo. Complete documentation set present in `docs/` folder.

---

## 27. MVP Release Checklist

- [x] Application launches without crash.
- [x] Local scanner indexes music and videos.
- [x] Music player (seek, queue, shuffle, repeat, background) verified.
- [x] Video player (seek, speed, fullscreen, resume position) verified.
- [x] Playlists, Favorites, and History persist across reboots.
- [x] Download manager handles queue, progress, cancel, retry, and library ingestion.
- [x] `flutter analyze` and `flutter test` pass clean.

---

## 28. Definition of Done

<div align="center">

> **A feature is DONE only when implementation, UI connections, database persistence, loading/empty/error UI states, edge case handling, and unit/widget tests are complete and verified.**

</div>
