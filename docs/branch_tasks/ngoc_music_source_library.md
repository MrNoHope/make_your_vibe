# Ngọc

Branch: feature/ngoc-music-source-library

Phần phụ trách:
- Music source
- Search nhạc
- Thư viện bài hát
- Chuẩn bị nguồn nhạc online sau này
- Cải thiện dữ liệu bài hát và playlist

Các file chính:
- lib/services/music_source_service.dart
- lib/services/simpmusic_source_service.dart
- lib/models/song.dart
- lib/data/demo_data.dart
- lib/screens/search/search_page.dart
- lib/screens/library/playlist_detail_screen.dart
- lib/controllers/vibe_controller.dart

Code cần làm thêm:
- Tạo music_source_service.dart để tách nguồn nhạc ra khỏi UI.
- Tạo simpmusic_source_service.dart nếu cần chuẩn bị hướng nguồn nhạc online.
- Cải thiện Search Screen.
- Cải thiện Playlist Detail.
- Tách dữ liệu bài hát demo ra service rõ ràng hơn.
- Không đụng phần sound ambient vì phần đó đã có người làm.
