import 'package:flutter_test/flutter_test.dart';
import 'package:make_your_vibe/app.dart';
import 'package:make_your_vibe/models/playlist.dart';
import 'package:make_your_vibe/models/song.dart';
import 'package:make_your_vibe/screens/splash_screen.dart';

void main() {
  testWidgets('App starts', (tester) async {
    await tester.pumpWidget(const MakeYourVibeApp());

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(find.text('Connect Spotify'), findsNothing);
    expect(find.text('Đăng nhập vào Make Your Vibe'), findsOneWidget);
  });

  test('Playlist JSON keeps mixed uploaded and online songs', () {
    const playlist = Playlist(
      id: 'mixed-album',
      title: 'Album cá nhân',
      songs: [
        Song(
          id: 'upload-1',
          title: 'Bản upload',
          artist: 'Tôi',
          streamUrl: 'https://example.com/upload.mp3',
          sourceType: 'upload',
          sourceId: 'songs/upload-1.mp3',
        ),
        Song(
          id: 'youtube-1',
          title: 'Bản online',
          artist: 'Nghệ sĩ',
          sourceType: 'youtube',
          sourceId: 'youtube-1',
        ),
      ],
    );

    final restored = Playlist.fromJson(playlist.toJson());

    expect(restored.songs, hasLength(2));
    expect(restored.songs.first.sourceType, 'upload');
    expect(restored.songs.last.sourceType, 'youtube');
  });
}
