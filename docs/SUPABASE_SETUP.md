# Supabase Storage setup

Use Firebase for Auth and Firestore. Use Supabase only for uploaded files.

## Buckets

Create two public buckets in Supabase Storage:

```text
songs
covers
```

Recommended limits:

```text
songs: 50 MB, audio/mpeg, audio/mp4, audio/wav, audio/x-wav, video/mp4
covers: 5 MB, image/jpeg, image/png, image/webp
```

Public buckets make playback URLs stable for demos. No expiring signed token is
needed when the user opens the app again later.

Fast path: run [supabase_storage_setup.sql](supabase_storage_setup.sql) in
Supabase SQL Editor.

## App config

Default demo config is in `lib/core/supabase_config.dart`. Override it when
needed:

```powershell
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=your-key
```

## Storage policy

Firebase Third-party Auth is enabled for `make-your-vibe`. Policies use
`anon, authenticated` because Firebase tokens may not include a Supabase
`role` claim, but the policy still requires a valid Firebase JWT:

```sql
bucket_id in ('songs', 'covers')
and (storage.foldername(name))[1] = 'users'
and (storage.foldername(name))[2] = auth.jwt() ->> 'sub'
and auth.jwt() ->> 'aud' = 'make-your-vibe'
and auth.jwt() ->> 'iss' = 'https://securetoken.google.com/make-your-vibe'
```
