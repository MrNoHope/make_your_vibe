# Firebase library setup

App now uses Firebase + Supabase:

- Firebase Auth: Google, Facebook, email login.
- Cloud Firestore: personal albums, saved YouTube songs, uploaded song metadata.
- Supabase Storage: uploaded audio files, album covers, song covers.

Current demo project:

```text
projectId: make-your-vibe
androidPackage: com.makeyourvibe.app
firebaseRedirectUri: https://make-your-vibe.firebaseapp.com/__/auth/handler
```

## Sign-in setup

Firebase Console > Authentication > Get started:

- Enable Email/Password.
- Enable Google.
- Enable Facebook with the Meta app ID/secret.

For Facebook, add this valid OAuth redirect URI in Meta Developer Console:

```text
https://make-your-vibe.firebaseapp.com/__/auth/handler
```

Google Sign-In on Android reads the Web OAuth client ID from
`android/app/google-services.json`. You can override it for local testing with:

```powershell
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

or build APK with:

```powershell
flutter build apk --debug --split-per-abi --dart-define=GOOGLE_WEB_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

## Firestore data

```text
users/{uid}/albums/{albumId}
users/{uid}/albums/{albumId}/items/{songId}
users/{uid}/songs/{songId}
users/{uid}/sharedAlbums/{shareCode}
sharedAlbums/{shareCode}
```

YouTube songs store metadata only:

```text
sourceType: youtube
sourceId: <youtube video id>
coverUrl: <youtube thumbnail>
streamUrl: ""
```

Uploaded songs store Supabase Storage public URLs:

```text
sourceType: upload
sourceId: songs/users/<uid>/audio/<file>
streamUrl: <supabase public url>
```

Shared albums store a snapshot of album metadata and song metadata in
`sharedAlbums/{shareCode}`. Friends import the share code into
`users/{uid}/sharedAlbums/{shareCode}` and stream from the stored YouTube id or
uploaded file URL.

## Firestore rules

Firebase Console > Firestore Database > Rules:

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null
        && request.auth.uid == userId;
    }

    match /sharedAlbums/{shareId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
        && request.resource.data.ownerId == request.auth.uid;
      allow update, delete: if request.auth != null
        && resource.data.ownerId == request.auth.uid;
    }
  }
}
```

## Supabase Storage

Supabase project needs two public buckets:

```text
songs
covers
```

Uploads go to `users/<firebase_uid>/audio/...`, `users/<firebase_uid>/covers/songs/...`,
and `users/<firebase_uid>/covers/albums/...`.

For class demo, keep uploaded MP3 files under 10 MB each. Album app entries do
not upload files; they only save YouTube IDs when the user adds a song to a
personal album.
