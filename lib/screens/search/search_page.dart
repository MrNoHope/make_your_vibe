import 'package:flutter/material.dart';

import '../../controllers/vibe_controller.dart';
import '../../core/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/song_widgets.dart';

class SearchPage extends StatefulWidget {
  final VibeController controller;

  const SearchPage({
    super.key,
    required this.controller,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    await widget.controller.searchSongs(textController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return PageScroll(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TopBar(title: 'Search'),
              const SizedBox(height: 14),
              TextField(
                controller: textController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => submit(),
                decoration: InputDecoration(
                  hintText: 'Nhập tên bài hát, ca sĩ...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    onPressed: submit,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (widget.controller.searching)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                SongList(
                  songs: widget.controller.searchResults,
                  activeId: widget.controller.currentSong?.id,
                  onSongTap: (song) {
                    widget.controller.playSong(
                      song,
                      queue: widget.controller.searchResults,
                    );
                  },
                ),
              if (widget.controller.errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                BackendNotice(
                  icon: Icons.error_outline_rounded,
                  title: 'Lỗi',
                  message: widget.controller.errorMessage,
                ),
              ],
              if (!widget.controller.searching && widget.controller.searchResults.isEmpty) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    SearchChip(label: 'Sơn Tùng', onTap: () => quickSearch('Sơn Tùng')),
                    SearchChip(label: 'Lofi', onTap: () => quickSearch('lofi')),
                    SearchChip(label: 'Chill', onTap: () => quickSearch('chill music')),
                    SearchChip(label: 'V-pop', onTap: () => quickSearch('vpop')),
                    SearchChip(label: 'Jazz', onTap: () => quickSearch('jazz music')),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void quickSearch(String value) {
    textController.text = value;
    submit();
  }
}

class SearchChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const SearchChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Chip(
        label: Text(label),
        labelStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
        ),
        backgroundColor: AppColors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}
