part of app_controller;

extension AppCommunityActions on AppController {
  List<CommunityPost> get community {
    final profileName = user?.displayName ?? 'Make Your Vibe User';
    return [
      const CommunityPost(
        id: 'p1',
        author: 'Linh Chill',
        title: 'Study night',
        caption: 'Lofi + mưa nhẹ cho buổi học tập trung.',
        songId: '60ItHLz5WEA',
        vibeId: 'sample_study',
        likes: 128,
      ),
      const CommunityPost(
        id: 'p2',
        author: 'Minh Ocean',
        title: 'Deep sleep',
        caption: 'Sóng biển êm kết hợp brown noise.',
        vibeId: 'sample_sleep',
        likes: 94,
      ),
      const CommunityPost(
        id: 'p3',
        author: 'An Acoustic',
        title: 'Coffee morning',
        caption: 'Một không gian cà phê ấm và dễ chịu.',
        songId: 'hT_nvWreIhg',
        likes: 76,
      ),
      ...vibes
          .where((vibe) => vibe.isPublic && !vibe.id.startsWith('sample_'))
          .map(
            (vibe) => CommunityPost(
              id: 'vibe_${vibe.id}',
              author: profileName,
              title: vibe.name,
              caption: vibe.description.isEmpty
                  ? tr('Vibe vừa được chia sẻ.', 'A newly shared Vibe.')
                  : vibe.description,
              vibeId: vibe.id,
              likes: vibe.likes,
            ),
          ),
      ...uploads.where((song) => song.isPublic).map(
            (song) => CommunityPost(
              id: 'song_${song.id}',
              author: profileName,
              title: song.title,
              caption: tr(
                'Bài nhạc mới của ${song.artist}.',
                'New music by ${song.artist}.',
              ),
              songId: song.id,
            ),
          ),
    ];
  }

  Future<void> togglePostLike(String id) async {
    likedPosts.contains(id) ? likedPosts.remove(id) : likedPosts.add(id);
    await store.setMaps(
      _key('liked_posts'),
      likedPosts.map((item) => {'id': item}),
    );
    notifyListeners();
  }

  Future<void> togglePostSave(String id) async {
    savedPosts.contains(id) ? savedPosts.remove(id) : savedPosts.add(id);
    await store.setMaps(
      _key('saved_posts'),
      savedPosts.map((item) => {'id': item}),
    );
    notifyListeners();
  }

  Future<void> shareText(String text) async {
    await Share.share(text);
  }
}
