# Cull – iOS Photo Management App

## Overview

**Cull** is an iOS app that helps users clean up and organize their photo library using an intuitive swipe-based interface inspired by Tinder. The name comes from the photography term "culling" — the process of sorting through photos to keep only the best ones.

---

## Core Concept

Users are presented with their photos one at a time and make quick decisions via swipe gestures:

| Gesture | Action |
|---|---|
| Swipe Right | Keep the photo |
| Swipe Left | Delete the photo |
| Swipe Down *(planned)* | Move to a specific folder/album |
| Swipe Up *(planned)* | Favorite / star the photo |
| Tap | View photo in detail before deciding |

---

## MVP Features (v1.0)

- [ ] Display photos from the user's camera roll one at a time
- [ ] Swipe right to keep a photo
- [ ] Swipe left to mark a photo for deletion
- [ ] Confirmation screen before permanently deleting marked photos
- [ ] Progress indicator (e.g. "124 of 1,840 photos reviewed")
- [ ] Session summary: how many kept vs. deleted, storage freed
- [ ] Undo last swipe gesture
- [ ] Onboarding flow explaining the swipe mechanics

---

## Planned Features (v1.1+)

- [ ] Swipe down to move photo into a chosen album/folder
- [ ] Swipe up to add photo to Favorites
- [ ] Smart suggestions (e.g. duplicates, blurry photos, screenshots)
- [ ] Filter by date range, album, or media type before culling session
- [ ] Batch mode: review by event or date group
- [ ] iCloud Photos support
- [ ] Stats dashboard: storage freed over time
- [ ] Customizable swipe actions

---

## Tech Stack

- **Platform:** iOS (iPhone-first, iPad later)
- **Language:** Swift
- **UI Framework:** SwiftUI
- **Photo Access:** PhotoKit (`PHPhotoLibrary`)
- **Minimum iOS Version:** iOS 16+

---

## Design Guidelines

- **Tone:** Clean, minimal, satisfying
- **Primary Action:** The swipe gesture should feel fluid and responsive with haptic feedback
- **Color Palette:** Neutral background, green for keep, red for delete (consistent with user expectations)
- **Typography:** System font (SF Pro) for native feel
- **Animations:** Card stack effect, smooth swipe transitions

---

## Project Structure (Suggested)

```
Cull/
├── App/
│   └── CullApp.swift
├── Views/
│   ├── OnboardingView.swift
│   ├── SwipeCardView.swift
│   ├── SessionSummaryView.swift
│   └── SettingsView.swift
├── ViewModels/
│   ├── PhotoSessionViewModel.swift
│   └── LibraryViewModel.swift
├── Models/
│   ├── Photo.swift
│   └── SwipeDecision.swift
├── Services/
│   ├── PhotoLibraryService.swift
│   └── DeletionService.swift
└── Resources/
    └── Assets.xcassets
```

---

## Permissions Required

- `NSPhotoLibraryUsageDescription` – to read photos
- `NSPhotoLibraryAddUsageDescription` – to modify/delete photos

---

## App Store Metadata (Draft)

- **App Name:** Cull
- **Subtitle:** Swipe to clean your photos
- **Category:** Photo & Video / Productivity
- **Keywords:** photo cleaner, delete photos, swipe, organize, storage, photo manager

---

## Notes

- Deleted photos should go to iOS "Recently Deleted" album first (standard PhotoKit behavior), giving users a 30-day safety net
- Never permanently delete without explicit user confirmation
- Session state should be saved so users can pause and resume a culling session