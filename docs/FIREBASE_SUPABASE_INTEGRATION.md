# Firebase + Supabase setup

Branch này thêm phần đăng nhập bằng Firebase và lưu thư viện nhạc bằng Supabase.

## Code chính

- `lib/main.dart`: khoi tao Firebase va Supabase truoc khi mo app.
- `lib/services/user_gateway.dart`: dang nhap email/password, Google, Facebook bang Firebase Auth.
- `lib/services/supabase_gateway.dart`: tao Supabase client, gui Firebase ID token sang Supabase.
- `lib/services/library_gateway.dart`: luu album, bai hat upload, bai hat online vao Supabase.
- `lib/core/supabase_config.dart`: doc Supabase URL/key tu `--dart-define`.
- `android/app/build.gradle.kts`: tu apply Google Services khi co `google-services.json`.
- `android/app/src/main/AndroidManifest.xml`: khai bao Facebook login va audio foreground service.

## Dat file Firebase o dau

Dat file Firebase Android tai:

```text
android/app/google-services.json
```

Neu tao lai Firebase project, chay:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure
```

File FlutterFire option nam tai:

```text
lib/firebase_options.dart
```

Android build se lay config tu `android/app/google-services.json`. Khong can sua Gradle them vi code da co san:

```kotlin
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
```

## Dat file Facebook o dau

Dat Facebook app id va client token tai:

```text
android/app/src/main/res/values/facebook_auth.xml
```

Mau file:

```xml
<resources>
    <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
    <string name="fb_login_protocol_scheme">fbYOUR_FACEBOOK_APP_ID</string>
    <string name="facebook_client_token">YOUR_FACEBOOK_CLIENT_TOKEN</string>
</resources>
```

Khong dua Facebook App Secret vao app mobile hoac GitHub.

## Cai Supabase

1. Mo Supabase Dashboard.
2. Tao project.
3. Mo SQL Editor.
4. Copy toan bo noi dung file nay va Run:

```text
docs/supabase_setup.sql
```

SQL se tao:

- `albums`
- `songs`
- `album_songs`
- bucket `songs`
- bucket `covers`
- RLS policy theo Firebase UID.

## Ket noi Supabase voi Firebase Auth

Trong Supabase Dashboard:

1. Mo `Authentication`.
2. Mo `Third-party Auth`.
3. Bat Firebase.
4. Nhap Firebase project id.
5. Dien thong tin/JWKS/service account theo yeu cau cua Supabase.

Khong commit service role key, private key, App Secret len GitHub.

## Chay app

Chay binh thuong neu da dat URL/key mac dinh trong `lib/core/supabase_config.dart`.

Neu muon truyen bang lenh, dung:

```powershell
flutter run --dart-define=SUPABASE_URL="https://YOUR_PROJECT.supabase.co" --dart-define=SUPABASE_PUBLISHABLE_KEY="YOUR_SUPABASE_PUBLISHABLE_KEY"
```

Neu dashboard chi co anon public key:

```powershell
flutter run --dart-define=SUPABASE_URL="https://YOUR_PROJECT.supabase.co" --dart-define=SUPABASE_ANON_KEY="YOUR_SUPABASE_ANON_KEY"
```

Neu test nhac tren Android emulator voi proxy local:

```powershell
dart run bin/music_proxy.dart
flutter run --dart-define=MUSIC_API_BASE_URL="http://10.0.2.2:8765"
```

## Kiem tra nhanh

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```
