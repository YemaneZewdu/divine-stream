# Divine Stream - Audio Streaming App

## 🎵 What is this project?

**Divine Stream** is a Flutter mobile app (Android & iOS) built with the **Stacked** architecture.
It streams religious audio content (hymns, prayers, sermons) **directly from public Google Drive folders**. Each Drive **subfolder becomes a playlist**; audio streams from Drive. The app supports background playback with lock-screen / notification / Bluetooth controls.

---

## ✨ Features

* Import a Google Drive folder (paste folder link) → creates a playlist.
* Support nested subfolders (each subfolder = playlist).
* Stream audio from Drive (direct `alt=media` links).
* Playback controls: Play / Pause / Next / Previous / Seek +/-10s, slider with buffering state.
* Auto-advance to the next track when the current finishes.
* Lock-screen/notification + Bluetooth controls (play/pause/next/prev).
* Refresh playlists to fetch newly added audio files.
* Offline playlist metadata via Hive (audio itself is streamed).

---

## 📦 Tech stack & main packages

* Flutter
* Architecture: **Stacked** (View / ViewModel / Services)
* Background & lock screen: **audio\_service**
* Audio playback: **just\_audio**
* Google Drive access: simple REST calls (public folders) via `http`
* Local cache: **hive** + **hive\_flutter**
* DI / service locator: **get\_it** (via Stacked generator)
* Other useful packages: `stacked_services`, `stacked_cli`
---

## 📁 Project structure (high level)

```
lib/
├── main.dart
├── app/                # Stacked app config, locator, router
├── models/             # AudioFile, Playlist
├── services/           # Audio handler, audio player wrapper, Drive + playlist services
├── ui/
│   ├── views/          # Home, Playlist, Player
│   └── widgets/        # Playback controls, dialogs
└── helpers/
```

---

## ⚙️ Configuration & setup

### Prerequisites

* Flutter SDK (stable)
* Xcode (macOS, for iOS) and/or Android Studio
* A Google Cloud project with **Google Drive API enabled** (see below)

### Google Drive (public folders)

1. In Google Drive, create a folder and upload audio files (`.mp3`, `.m4a`, etc.).
2. For each audio file, set **Share → Anyone with the link → Viewer** (public access).
3. For ease, make the containing folder shareable (so files inherit access).
4. Create an API key in Google Cloud Console and **enable Drive API** for the project.

> **Important:** If you see errors such as `API_KEY_SERVICE_BLOCKED` or `Requests to this API ... are blocked`, go to Google Cloud Console → APIs & Services → Library → enable *Google Drive API*. Check API key restrictions and enable Drive scope.

### Where to put the API key

* The app uses the API key to build public `alt=media` URLs. Place your API key in a safe config file or environment variable. Example:

    * create `lib/config.dart` (not committed):

      ```dart
      const String kGoogleApiKey = 'YOUR_API_KEY';
      ```
    * Or use a `.env` approach and inject at runtime.
* **Do not commit** API keys to public repos.

### iOS background config

* `ios/Runner/Info.plist` — add:

  ```xml
  <key>UIBackgroundModes</key>
  <array>
    <string>audio</string>
  </array>
  ```
* In Xcode: Target → Signing & Capabilities → add **Background Modes** → enable **Audio, AirPlay & Picture in Picture**.

### Android config

* `android/app/src/main/AndroidManifest.xml` — add:

  ```xml
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
  ```
* The `audio_service` plugin handles much of the notification plumbing; the app initializes an `AudioHandler` with proper `AudioServiceConfig`.

---

## 🧭 How to run

1. Clone repo:

   ```bash
   git clone <repo-url>
   cd audio-streaming-app
   flutter pub get
   ```
2. Configure your API key (see above).
3. Generate code (stacked / build\_runner) if needed:

   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
4. Run on device:

   ```bash
   flutter run
   ```

   For iOS, use Xcode if you need to set capabilities.

---

## 🧪 Testing & common dev commands

* Static analysis:

  ```bash
  flutter analyze
  ```
* Code gen:

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
* If using `stacked_cli` to generate views:

  ```bash
  flutter pub global activate stacked_cli
  stacked create view home
  ```

