import 'package:flutter/material.dart';

import '../../app_dependencies.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.c,
    required this.onNavigate,
  });

  final AppController c;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final songs = c.recent.isNotEmpty ? c.recent : c.seedSongs;
    final study = c.vibes.where((vibe) => vibe.id == 'sample_study').firstOrNull;
    final sleep = c.vibes.where((vibe) => vibe.id == 'sample_sleep').firstOrNull;
    final displayName = c.user?.displayName.trim() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            AppLogo(size: 38),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'Make Your Vibe',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: c.tr('Tìm kiếm', 'Search'),
            onPressed: () => onNavigate(1),
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: [
          if (displayName.isNotEmpty) ...[
            Text(
              c.tr('Xin chào, $displayName', 'Hello, $displayName'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.tertiary,
                ],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.tr(
                    'Không gian âm thanh của riêng bạn',
                    'Your personal sound space',
                  ),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  c.tr(
                    'Chọn nhạc, phối đúng 10 âm thanh Ambient và lưu thành một Vibe.',
                    'Choose music, mix the 10 included ambient sounds, and save a Vibe.',
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => onNavigate(2),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: Text(c.tr('Tạo Vibe', 'Create Vibe')),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => onNavigate(1),
                      icon: const Icon(Icons.search_rounded),
                      label: Text(c.tr('Tìm nhạc', 'Find music')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SectionTitle(c.tr('Truy cập nhanh', 'Quick access')),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 360;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: narrow ? 1 : 2,
                childAspectRatio: narrow ? 4.2 : 2.6,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  _QuickCard(
                    icon: Icons.favorite_rounded,
                    title: c.tr('Bài hát đã thích', 'Liked songs'),
                    subtitle: '${c.liked.length}',
                    onTap: () => onNavigate(3),
                  ),
                  _QuickCard(
                    icon: Icons.graphic_eq_rounded,
                    title: c.tr('Ambient Mixer', 'Ambient Mixer'),
                    subtitle: c.tr('10 âm thanh', '10 sounds'),
                    onTap: () => onNavigate(2),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          SectionTitle(c.tr('Vibe theo tâm trạng', 'Vibes by mood')),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _Mood(
                  '📚',
                  c.tr('Học tập', 'Study'),
                  () {
                    if (study != null) c.applyVibe(study);
                  },
                ),
                _Mood(
                  '😴',
                  c.tr('Ngủ ngon', 'Sleep'),
                  () {
                    if (sleep != null) c.applyVibe(sleep);
                  },
                ),
                _Mood(
                  '☕',
                  c.tr('Cà phê', 'Coffee'),
                  () {
                    c.search('coffee shop jazz');
                    onNavigate(1);
                  },
                ),
                _Mood(
                  '🏃',
                  c.tr('Tập luyện', 'Workout'),
                  () {
                    c.search('workout music');
                    onNavigate(1);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SectionTitle(c.tr('Nghe gần đây', 'Recently played')),
          const SizedBox(height: 4),
          for (final song in songs)
            SongTile(c: c, song: song, queue: songs),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _Mood extends StatelessWidget {
  const _Mood(this.icon, this.label, this.onTap);

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ActionChip(
          onPressed: onTap,
          avatar: Text(icon),
          label: Text(label),
        ),
      );
}
