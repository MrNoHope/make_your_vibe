# Supabase setup

Firebase stays the auth source. Supabase stores user songs, covers, albums,
and album-song links.

## 1. Create Supabase project

Current project:

- Project: `make-your-vibe`
- Region: `ap-southeast-1`
- Project URL: `https://diumqxbwtdpsyxmhptim.supabase.co`
- Publishable key: `sb_publishable_PCWJRwsAVkauw67S9XucQw_L5Kg6o85`

Run Flutter with:

```powershell
flutter run --dart-define=SUPABASE_URL="https://diumqxbwtdpsyxmhptim.supabase.co" --dart-define=SUPABASE_PUBLISHABLE_KEY="sb_publishable_PCWJRwsAVkauw67S9XucQw_L5Kg6o85"
```

`SUPABASE_ANON_KEY` also works if your dashboard still shows an anon public key.

## 2. Connect Firebase Auth

In Supabase Dashboard:

1. Open Authentication > Third-party Auth.
2. Enable Firebase.
3. Use Firebase project id `make-your-vibe`.
4. Configure the Firebase service account/JWKS settings requested by Supabase.

The included RLS policies work with normal Firebase ID tokens. They check the
Firebase issuer, project id, and UID in JWT `sub`, so no custom Firebase role
claim is required.

## 3. Create tables, buckets, and policies

Run [supabase_setup.sql](supabase_setup.sql) in Supabase SQL Editor.

It creates:

- `albums`
- `songs`
- `album_songs`
- private storage bucket `songs`
- private storage bucket `covers`
- RLS policies keyed by Firebase UID from JWT `sub`

## 4. App behavior

The Library tab loads Supabase albums/songs after login. Upload paths use:

```text
users/<firebase_uid>/audio/...
users/<firebase_uid>/songs/...
users/<firebase_uid>/albums/...
```

Audio playback uses signed URLs, valid for 6 hours.
