import 'package:flutter/material.dart';

import '../../controllers/vibe_controller.dart';
import '../../models/song.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/song_widgets.dart';

// Trang tìm kiếm cho phép người dùng nhập từ khóa và lọc bài hát. 
class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    required this.controller,
    required this.onOpenPlayer,
  });

  final VibeController controller;
  final VoidCallback onOpenPlayer;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // TextEditingController giữ nội dung người dùng nhập vào ô tìm kiếm để có thể lọc danh sách bài hát.
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  // Getter này biến chuỗi tìm kiếm thành danh sách kết quả phù hợp để render ra UI.
  List<Song> get results {
    final query = search.text.trim().toLowerCase();

    // Nếu không nhập gì thì hiển thị toàn bộ danh sách bài hát.
    if (query.isEmpty) {
      return widget.controller.songs;
    }

    // Tìm trong tiêu đề, nghệ sĩ, album hoặc thể loại.
    return widget.controller.songs.where((song) {
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query) ||
          song.album.toLowerCase().contains(query) ||
          song.category.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Bố cục trang Search gồm một tiêu đề, ô nhập, nhóm thể loại và khu vực kết quả.
    return AppPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 180),
        children: [
          // Tiêu đề trang tìm kiếm.
          const Text(
            'Search',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          // Ô nhập là phần trung tâm của trang tìm kiếm. Mỗi lần nhập đều kích hoạt setState để cập nhật kết quả ngay lập tức.
          TextField(
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Bạn muốn nghe gì?',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 22),
          // Phần này cung cấp các thể loại gợi ý để người dùng có thể khám phá nhanh mà không cần nhập từ khóa.
          const SectionHeader(title: 'Khám phá thể loại'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              GenreChip(text: 'Pop'),
              GenreChip(text: 'Lofi'),
              GenreChip(text: 'Study'),
              GenreChip(text: 'Chill'),
              GenreChip(text: 'Acoustic'),
              GenreChip(text: 'Instrumental'),
            ],
          ),
          const SizedBox(height: 24),
          // Đây là khu vực render danh sách bài hát phù hợp với truy vấn hiện tại.
          const SectionHeader(title: 'Kết quả'),
          const SizedBox(height: 8),
          ...results.map((song) {
            return SongListTile(
              controller: widget.controller,
              song: song,
              onTap: () async {
                await widget.controller.playSong(song);
                widget.onOpenPlayer();
              },
            );
          }),
        ],
      ),
    );
  }
}
