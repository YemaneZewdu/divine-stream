# Divine Stream - Audio Streaming App

## Overview
Divine Stream is a Flutter app for iOS and Android that delivers hymns, sermons, and other spiritual audio content. The legacy Google Drive integration 
has been replaced with a Firebase-backed pipeline, so playlists and streamable URLs now come from Firebase instead of public Drive folders. 
The app keeps its MVVM structure via Stacked, offers background playback, and continues to support offline-friendly metadata caching.

## Key Highlights
- Streams audio from Firebase-managed manifests (Firestore + Cloud Storage URLs)
- Automatic playlist organisation for nested folders
- Background playback with lock-screen and Bluetooth controls
- Offline metadata cache for fast launches and browsing without network
- Clean MVVM architecture with testable services and view models

## Firebase Backend
- **Firestore manifests**: Cloud Functions populate a `manifests` collection; each document carries playlist metadata, 
    parent relationships, and signed stream URLs.
- **Cloud Storage delivery**: Audio files are stored in Firebase Storage; signed URLs are exposed through the manifests for secure playback.
- **Service layer**: `FirebasePlaylistLoader` converts manifest documents into the legacy `Playlist` model so the existing UI and caching 
    layers continue to work.

## Core Features
### Playlist & Library Management
- Three-level navigation (Home → Folder → Playlist)
- Numeric-aware sorting so "Track 2" appears before "Track 10"
- Swipe-to-delete, pull-to-refresh, and cached hierarchy for offline browsing

### Audio Experience
- just_audio + audio_service for seamless playback and background control
- Lock-screen, Control Center, and Bluetooth transport actions
- Resume last position and auto-advance to the next track

### Reliability & UX
- Hive-backed metadata cache for instant startup
- Connectivity awareness with graceful offline messaging
- Consistent MVVM organisation for maintainability

## Tech Stack
- **Framework**: Flutter (Dart 3+)
- **Architecture**: Stacked (GetIt DI, RxDart helpers)
- **Audio**: just_audio, audio_service
- **Storage**: Hive, hive_flutter
- **Firebase**: cloud_firestore, firebase_core, firebase_storage (via generated manifests)
- **Utilities**: connectivity_plus, stacked_services, fluttertoast, flutter_native_splash
- **Tooling**: build_runner, stacked_generator, mockito

## Project Structure
```
divine_stream/
├── lib/
│   ├── main.dart
│   ├── app/                    # Stacked configuration (locators, routes, dialogs)
│   ├── models/                 # AudioFile, Playlist, ParentFolderGroup entities
│   ├── services/
│   │   ├── firebase_playlist_loader.dart  # Fetch Firebase manifests
│   │   ├── playlist_service.dart          # Cache + domain orchestration
│   │   ├── audio_player_service.dart      # Playback facade
│   │   ├── audio_handler_impl_service.dart# Background handler
│   │   ├── audio_cache_service.dart       # Hive integration
│   │   └── connectivity_service.dart      # Network monitoring
│   ├── ui/                    # Views, dialogs, bottom sheets, shared widgets
│   ├── helpers/               # App helpers and colour palette
│   └── utils/                 # Sorting + miscellaneous utilities
├── ios/, android/, web/, macos/, windows/, linux/  # Platform targets
├── assets/                    # Artwork and static assets
├── TECHNICAL_DOCUMENTATION.md
├── FEATURES_SUMMARY.md
├── INTERVIEW_GUIDE.md
├── pubspec.yaml
└── README.md
```

## Getting Started
1. Install Flutter (see `flutter --version` requirement in the docs).
2. Run `flutter pub get`.
3. Configure Firebase: download the `google-services.json` / `GoogleService-Info.plist` files and place them under 
   `android/app` and `ios/Runner` respectively.
4. Ensure the Cloud Function that publishes playlist manifests is deployed and the `manifests` collection is populated.
5. Run `flutter run` (or build via Xcode/Android Studio) and sign in with a Firebase user that has access to the manifests.

## Contributing
Issues and pull requests are welcome. Please follow the MVVM conventions already established in the codebase and update tests or documentation 
when behaviour changes.
