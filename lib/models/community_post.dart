class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.author,
    required this.title,
    required this.caption,
    this.songId = '',
    this.vibeId = '',
    this.likes = 0,
  });

  final String id;
  final String author;
  final String title;
  final String caption;
  final String songId;
  final String vibeId;
  final int likes;
}
