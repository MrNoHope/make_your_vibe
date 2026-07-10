# Music API proxy

Flutter Web cannot call YouTube directly because the browser blocks those
requests with CORS. Run this local proxy before the web demo:

```powershell
dart run bin/music_proxy.dart
```

Default URL:

```text
http://localhost:8765
```

Use another API URL when building Flutter Web:

```powershell
flutter build web --dart-define=MUSIC_API_BASE_URL=https://your-api.example.com
```

Endpoints:

- `GET /health`
- `GET /api/search?q=<keyword>`
- `GET /api/resolve?id=<youtube_video_id>`
