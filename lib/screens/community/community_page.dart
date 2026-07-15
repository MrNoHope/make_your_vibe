import 'package:flutter/material.dart';

import '../../app_dependencies.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key, required this.c});

  final AppController c;

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  bool savedOnly = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final posts = savedOnly
        ? c.community.where((post) => c.savedPosts.contains(post.id)).toList()
        : c.community;
    return Scaffold(
      appBar: AppBar(
        title: Text(c.tr('Khám phá cộng đồng', 'Community Explore')),
        actions: [
          IconButton(
            tooltip: savedOnly
                ? c.tr('Xem tất cả', 'Show all')
                : c.tr('Nội dung đã lưu', 'Saved content'),
            onPressed: () => setState(() => savedOnly = !savedOnly),
            icon: Badge(
              label: Text('${c.savedPosts.length}'),
              isLabelVisible: c.savedPosts.isNotEmpty,
              child: Icon(
                savedOnly ? Icons.bookmark : Icons.bookmark_border,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: posts.isEmpty
          ? EmptyState(
              icon: Icons.bookmark_border,
              text: c.tr(
                'Bạn chưa lưu nội dung cộng đồng nào.',
                'You have not saved community content yet.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final post in posts)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(child: Text(_initial(post.author))),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  post.author,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                c.tr('Công khai', 'Public'),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            post.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(post.caption),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.start,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 2,
                            runSpacing: 6,
                            children: [
                              IconButton(
                                onPressed: () => c.togglePostLike(post.id),
                                icon: Icon(
                                  c.likedPosts.contains(post.id)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: c.likedPosts.contains(post.id)
                                      ? Colors.pink
                                      : null,
                                ),
                              ),
                              Text(
                                '${post.likes + (c.likedPosts.contains(post.id) ? 1 : 0)}',
                              ),
                              IconButton(
                                onPressed: () => c.togglePostSave(post.id),
                                icon: Icon(
                                  c.savedPosts.contains(post.id)
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                ),
                              ),
                              IconButton(
                                onPressed: () => c.shareText(
                                  '${post.title}\n${post.caption}',
                                ),
                                icon: const Icon(Icons.share_outlined),
                              ),
                              if (post.vibeId.isNotEmpty)
                                FilledButton.tonal(
                                  onPressed: () {
                                    final vibe = c.vibes
                                        .where((item) => item.id == post.vibeId)
                                        .firstOrNull;
                                    if (vibe != null) c.applyVibe(vibe);
                                  },
                                  child: Text(c.tr('Dùng Vibe', 'Use Vibe')),
                                )
                              else if (post.songId.isNotEmpty)
                                FilledButton.tonal(
                                  onPressed: () {
                                    final song = c.allSongs
                                        .where((item) => item.id == post.songId)
                                        .firstOrNull;
                                    if (song != null) {
                                      c.playSong(song, fromQueue: c.allSongs);
                                    }
                                  },
                                  child: Text(c.tr('Phát', 'Play')),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  String _initial(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }
}

