<div align="center">

# 🎨 MediaHub — UI & UX Design System

[![Document Version](https://img.shields.io/badge/Doc_Type-UI_Design_Spec-00599C?style=for-the-badge)](docs/UI_DESIGN.md)
[![Theme](https://img.shields.io/badge/Theme-Dark_%26_Light_Modes-2E7D32?style=for-the-badge)]()
[![Platform Layout](https://img.shields.io/badge/Layout-Adaptive_Mobile_%26_Desktop-FF6F00?style=for-the-badge)]()

---

**Detailed UI wireframes, screen hierarchy, design tokens, color palette, responsive breakpoints, accessibility rules, and widget structure for MediaHub.**

</div>

---

## 📑 Table of Contents

- [1. Purpose](#1-purpose)
- [2. UI Vision](#2-ui-vision)
- [3. Primary Navigation](#3-primary-navigation)
- [4. Main Screens](#4-main-screens)
- [5. App Layout](#5-app-layout)
- [6. Home Screen](#6-home-screen)
- [7. Media Library Screen](#7-media-library-screen)
- [8. Music Tab](#8-music-tab)
- [9. Video Tab](#9-video-tab)
- [10. Search & Filter](#10-search--filter)
- [11. Music Player UI](#11-music-player-ui)
- [12. Mini Player](#12-mini-player)
- [13. Full Player](#13-full-player)
- [14. Queue View](#14-queue-view)
- [15. Video Player UI](#15-video-player-ui)
- [16. Download Manager UI](#16-download-manager-ui)
- [17. Add Download Screen](#17-add-download-screen)
- [18. Download List Screen](#18-download-list-screen)
- [19. Download Task Cards](#19-download-task-cards)
- [20. Playlist Screen](#20-playlist-screen)
- [21. Playlist Detail Screen](#21-playlist-detail-screen)
- [22. Favorites Screen](#22-favorites-screen)
- [23. Playback History](#23-playback-history)
- [24. Continue Watching](#24-continue-watching)
- [25. Settings Screen](#25-settings-screen)
- [26. Media Directories](#26-media-directories)
- [27. Empty States](#27-empty-states)
- [28. Loading States](#28-loading-states)
- [29. Error States](#29-error-states)
- [30. Confirmation Dialogs](#30-confirmation-dialogs)
- [31. Media Context Menu](#31-media-context-menu)
- [32. Typography](#32-typography)
- [33. Spacing](#33-spacing)
- [34. Border Radius](#34-border-radius)
- [35. Icons](#35-icons)
- [36. Color System](#36-color-system)
- [37. Dark Mode](#37-dark-mode)
- [38. Light Mode](#38-light-mode)
- [39. Responsive Design](#39-responsive-design)
- [40. Desktop Layout](#40-desktop-layout)
- [41. Mobile Layout](#41-mobile-layout)
- [42. Accessibility](#42-accessibility)
- [43. Interaction Principles](#43-interaction-principles)
- [44. Feedback](#44-feedback)
- [45. UI State Model](#45-ui-state-model)
- [46. Component Reusability](#46-component-reusability)
- [47. UI and Business Logic Separation](#47-ui-and-business-logic-separation)
- [48. Home Screen Priority](#48-home-screen-priority)
- [49. Library Priority](#49-library-priority)
- [50. Download Priority](#50-download-priority)
- [51. Player Priority](#51-player-priority)
- [52. UI Architecture](#52-ui-architecture)
- [53. UI Development Order](#53-ui-development-order)
- [54. UI Prototype Principle](#54-ui-prototype-principle)
- [55. Final UI Principle](#55-final-ui-principle)

---

## 1. Purpose

This document defines the user interface and user experience design of MediaHub.

MediaHub is a local-first multimedia application that combines:
- Media downloading
- Local media management
- Music playback
- Video playback
- Playlist management
- Favorites
- Playback history

---

## 2. UI Vision

The UI should feel:
- 🎨 Modern and clean
- 🎧 Audio/video focused
- 📱 Responsive across mobile and desktop
- ⚡ Fast and reactive
- 💡 Intuitive with minimal workflow steps

---

## 3. Primary Navigation & 4. Main Screens

Navigation includes: `Home`, `Library`, `Downloads`, `Playlists`, `Settings`.

---

## 5. App Layout (Mobile vs Desktop Wireframes)

### Mobile Shell
```text
┌──────────────────────────────────────────────┐
│ [≡] Home                      [🔍] [⚙️]       │
├──────────────────────────────────────────────┤
│                                              │
│               Main Content Area              │
│                                              │
├──────────────────────────────────────────────┤
│ [Artwork] Track Title          [◄] [▶] [►]   │  ◄ Mini Player
├──────────────────────────────────────────────┤
│ 🏠 Home | 📚 Library | 📥 Downloads | 📑 Playlists │ ◄ Navigation Bar
└──────────────────────────────────────────────┘
```

### Desktop Shell
```text
┌──────────────┬─────────────────────────────────────────────┐
│ 🎧 MediaHub  │ Header (Search, Filters, Theme)             │
├──────────────┼─────────────────────────────────────────────┤
│ 🏠 Home      │                                             │
│ 📚 Library   │              Main Content Area              │
│ 📥 Downloads │                                             │
│ 📑 Playlists │                                             │
│ ⚙️ Settings  │                                             │
├──────────────┴─────────────────────────────────────────────┤
│ [Artwork] Track Title  [⏮] [⏯] [⏭] [🔀] [🔁]  ───🔊──  1:24/3:45 │
└────────────────────────────────────────────────────────────┘
```

---

## 6. Home Screen Wireframe

```text
┌──────────────────────────────────────────────┐
│ Welcome Back                                 │
├──────────────────────────────────────────────┤
│ Recently Played                              │
│ [Art1] Song 1    [Art2] Song 2    [Thumb1] Vid│
├──────────────────────────────────────────────┤
│ Continue Watching                            │
│ [Thumb] Video Title  ██████████░░ 65%         │
├──────────────────────────────────────────────┤
│ Quick Access                                 │
│ [ Favorites ]   [ Downloads ]   [ Playlists ]│
└──────────────────────────────────────────────┘
```

---

## 7. Media Library Screen (8. Music & 9. Video Tabs)

```text
┌──────────────────────────────────────────────┐
│ Library                                      │
│ [ Music ]  [ Videos ]  [ Favorites ]         │
├──────────────────────────────────────────────┤
│ Sort: [ Date Added ▼ ]    Filter: [ All ▼ ]  │
├──────────────────────────────────────────────┤
│ 🎵 Song Title 1                              │
│    Artist Name • Album Name           3:45   │
│                                              │
│ 🎵 Song Title 2                              │
│    Artist Name • Album Name           4:12   │
└──────────────────────────────────────────────┘
```

---

## 10. Search & Filter Bar Wireframe

```text
┌──────────────────────────────────────────────┐
│ 🔍 Search music, videos, artists...         │
├──────────────────────────────────────────────┤
│ Filter: (•) All  ( ) Music  ( ) Videos       │
└──────────────────────────────────────────────┘
```

---

## 11. Music Player UI (12. Mini Player, 13. Full Player, 14. Queue)

### Full Player View
```text
┌──────────────────────────────────────────────┐
│ 🅇 Close                                      │
│                                              │
│              ┌───────────────┐               │
│              │               │               │
│              │    ARTWORK    │               │
│              │               │               │
│              └───────────────┘               │
│                                              │
│              Track Title                     │
│              Artist Name                     │
│                                              │
│ 1:45 ───────────────●───────────────── 3:30  │
│                                              │
│       [🔀]   [⏮]   [ ⏯ ]   [⏭]   [🔁]        │
│                                              │
│ 📑 Queue (12 tracks remaining)               │
└──────────────────────────────────────────────┘
```

---

## 15. Video Player UI

```text
┌──────────────────────────────────────────────┐
│ ◄ Back           Video Title        [⚙️ 1.0x]│
│                                              │
│                                              │
│                  [   ⏯   ]                   │
│                                              │
│                                              │
│ 04:15 ──────────────●──────────────── 12:40 │
│ [⏮ 10s]   [ ⏯ ]   [⏭ 10s]         [⛶ Full]  │
└──────────────────────────────────────────────┘
```

---

## 16. Download Manager UI (17. Add Download, 18. Task List, 19. Task Cards)

```text
┌──────────────────────────────────────────────┐
│ Download Manager                             │
├──────────────────────────────────────────────┤
│ Paste Media URL:                             │
│ [ https://example.com/media.mp3            ] │
│ [ Download ]                                 │
├──────────────────────────────────────────────┤
│ Active Downloads (2)                         │
│                                              │
│ 🎵 Track Title 1.mp3                         │
│    Downloading... 4.2 MB / 8.5 MB (50%)      │
│    ████████████░░░░░░░  [⏸] [✖]             │
│                                              │
│ 🎬 Video Title.mp4                           │
│    Queued                                    │
└──────────────────────────────────────────────┘
```

---

## 20. Playlist Screen & 21. Playlist Detail

```text
┌──────────────────────────────────────────────┐
│ My Playlists                [+ New Playlist] │
├──────────────────────────────────────────────┤
│ 📁 Workout Beats (18 tracks)                 │
│ 📁 Chill Acoustic (24 tracks)                │
│ 📁 Roadtrip Videos (5 clips)                 │
└──────────────────────────────────────────────┘
```

---

## 22. Favorites & 23. Playback History & 24. Continue Watching

Displays bookmarked tracks, chronologically grouped history (`Today`, `Yesterday`, `Earlier`), and saved progress bars on videos.

---

## 25. Settings Screen & 26. Media Directories

Allows configuring folder scan paths (`E:\Music`, `E:\Videos`), setting default download folders, selecting App Theme (`Dark`, `Light`, `System`), and initiating manual rescans.

---

## 27. Empty States & 28. Loading & 29. Error States

Empty library placeholders present helpful action buttons (`[ Scan Media ]`). Error views describe what failed and recovery actions (`[ Retry ]`).

---

## 30. Confirmation Dialogs & 31. Context Menu

Context menus offer `Play`, `Add to Playlist`, `Favorite`, `View Details`, `Delete File`. Destructive file deletion prompts explicitly before disk removal.

---

## 32. Typography Hierarchy

| Level | Usage | Sample Size / Weight |
|---|---|---|
| **Page Title** | Top screen header | 24sp Bold |
| **Section Title** | Group header | 18sp Semi-Bold |
| **Media Title** | Primary track/video title | 16sp Medium |
| **Subtitle / Artist** | Secondary metadata | 14sp Regular |
| **Caption / Time** | Timestamps, file size | 12sp Light |

---

## 33. Spacing & 34. Corner Radius Tokens

- **Base Unit**: `4px`
- **Spacing Steps**: `4px`, `8px`, `12px`, `16px`, `24px`, `32px`, `48px`.
- **Corner Radii**: Buttons (`8px`), Cards (`12px`), Dialogs (`16px`).

---

## 35. Icons

Consistent Material/Feather icon set for Play, Pause, Previous, Next, Shuffle, Repeat, Favorite, Search, Download, Settings.

---

## 36. Color System & 37. Dark Mode & 38. Light Mode

```text
Semantic Palette Tokens:
├── Primary Accent: Deep Indigo / Vibrant Cyan
├── Background: Dark Gray (#121212) / Soft White (#F8F9FA)
├── Surface Cards: Dark Slate (#1E1E1E) / Pure White (#FFFFFF)
├── Text Primary: Pure White (#FFFFFF) / Dark Charcoal (#111111)
├── Text Secondary: Muted Gray (#AAAAAA) / Medium Gray (#666666)
└── Status: Success Green, Warning Amber, Error Red
```

---

## 39. Responsive Design (40. Desktop vs 41. Mobile Layouts)

- **Small Screen (<600dp)**: Bottom navigation, single column list, compact mini player.
- **Medium Screen (600-900dp)**: Navigation rail, two-column grid.
- **Large Screen (>900dp)**: Persistent sidebar navigation, multi-column media grid, expanded player controls.

---

## 42. Accessibility & 43. Interaction Principles

Semantics labels, contrast ratio standard compliance (WCAG AA), touch targets >= `48x48dp`, direct one-tap playback initiation.

---

## 44. Feedback & 45. UI State Model

Visual feedback via Snackbars ("Added to Favorites", "Download Started"). Standardized state tree: `Loading ──► Success ──► Empty ──► Error`.

---

## 46. Component Reusability

Shared widgets in `shared/widgets/`: `MediaCard`, `MediaListTile`, `MiniPlayer`, `EmptyState`, `ErrorView`.

---

## 47. UI & Business Logic Separation

Widgets consume state via Riverpod providers and invoke use cases. Widgets **never** call SQLite or disk APIs directly.

---

## 48. Home Priority, 49. Library Priority, 50. Download Priority, 51. Player Priority

Prioritize user action: Currently playing track > Recently played > Continue watching > Primary library lists.

---

## 52. UI Architecture & 53. UI Development Order

`App Shell ──► Navigation ──► Home ──► Library ──► Players ──► Downloads ──► Playlists ──► Settings`

---

## 54. UI Prototype Principle & 55. Final UI Principle

<div align="center">

> **MediaHub's interface should make the user's primary workflow feel natural: Acquire ──► Organize ──► Browse ──► Play**

</div>