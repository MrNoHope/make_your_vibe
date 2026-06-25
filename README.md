# Make Your Vibe

Flutter mobile music app demo for the course project.

## Current demo

- One-tap local demo login and register UI.
- Search and play YouTube videos with YouTube Data API v3.
- Import and play personal audio/video files from the device.
- Local favorites, playlists, albums-style library, and user profile.
- Demo data is stored locally as JSON. There is no backend yet.

## Run

Install Flutter, connect an Android device or start an emulator, then run:

```bash
flutter pub get
flutter run
```

Local MP3/video playback works without an API key.

YouTube search requires a YouTube Data API v3 key:

```bash
flutter run --dart-define=YOUTUBE_API_KEY=YOUR_KEY
```

Do not commit the real API key to this repository. Each team member can provide
their own key with `--dart-define`.

## Demo login

Open the Account tab and tap `Login`. The fields are prefilled and the password
is not checked. Authentication will be connected to a backend later.
