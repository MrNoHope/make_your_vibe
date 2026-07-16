# YouTube Data API

The app searches music with the official YouTube Data API v3 and plays online
YouTube songs with `youtube_player_flutter`.

Default demo key:

```text
lib/core/youtube_api_config.dart
```

Override it when running:

```powershell
flutter run --dart-define=YOUTUBE_API_KEY="YOUR_YOUTUBE_DATA_API_KEY"
```

Build APK:

```powershell
flutter build apk --debug --dart-define=YOUTUBE_API_KEY="YOUR_YOUTUBE_DATA_API_KEY"
```

Notes:

- No local music proxy is required.
- YouTube search uses `www.googleapis.com/youtube/v3/search`.
- Online YouTube songs are played by video id through the official iframe
  player.
- Uploaded Supabase Storage audio files still use `just_audio`.
