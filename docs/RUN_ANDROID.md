# Run Android build

## Install APK

Use this file from the project build output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

On Android, enable install from unknown sources for the app used to open the APK,
then install the APK.

## Build from source

Install Flutter, Android Studio, and Android SDK. Then run:

```powershell
flutter pub get
flutter run -d <device-id>
```

## Spotify config

For local Android builds, add Spotify credentials to `android/local.properties`.
This file is intentionally ignored by git.

```properties
spotify.clientId=YOUR_SPOTIFY_CLIENT_ID
spotify.clientSecret=YOUR_SPOTIFY_CLIENT_SECRET
```

The Android package and SHA1 registered in Spotify Dashboard must match:

```text
package: com.makeyourvibe.app
debug SHA1: 61:86:51:DE:0F:42:7E:71:B8:3D:14:20:D8:8A:93:13:F6:68:C6:02
redirect URI: makeyourvibe://spotify-callback
```

## Login

Google login uses Firebase Auth and `android/app/google-services.json`.
Facebook login uses Firebase Auth plus `android/app/src/main/res/values/facebook_auth.xml`.

If login fails on another build, add that build certificate SHA1 to Firebase and
download a fresh `google-services.json`.
