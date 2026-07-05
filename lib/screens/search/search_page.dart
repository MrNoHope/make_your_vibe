import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/common_widgets.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TopBar(title: 'Search'),
          const SizedBox(height: 14),
          const TextField(
            decoration: InputDecoration(
              hintText: 'Search songs, artists, albums...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Gợi ý tìm kiếm',
            action: 'Backend',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: const [
              SearchChip(label: 'Pop'),
              SearchChip(label: 'Lofi'),
              SearchChip(label: 'Study'),
              SearchChip(label: 'Chill'),
              SearchChip(label: 'Jazz'),
              SearchChip(label: 'Instrumental'),
            ],
          ),
          const SizedBox(height: 24),
          const BackendNotice(
            icon: Icons.search_off_rounded,
            title: 'Search backend not connected',
            message:
            'Real search results will appear here after the music source API is integrated.',
          ),
        ],
      ),
    );
  }
}

class SearchChip extends StatelessWidget {
  final String label;

  const SearchChip({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w900,
      ),
      backgroundColor: AppColors.green,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}