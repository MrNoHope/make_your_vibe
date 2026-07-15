import 'package:flutter/material.dart';

import '../../app_dependencies.dart';

class LibraryUploads extends StatelessWidget {
  const LibraryUploads({required this.c});

  final AppController c;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: () => _upload(context),
          icon: const Icon(Icons.upload_file),
          label: Text(c.tr('Đăng nhạc từ thiết bị', 'Upload from device')),
        ),
        const SizedBox(height: 12),
        if (c.uploads.isEmpty)
          EmptyState(
            icon: Icons.audio_file,
            text: c.tr(
              'Chưa có bài nhạc nào được đăng.',
              'No uploaded songs yet.',
            ),
          ),
        for (final song in c.uploads)
          SongTile(
            c: c,
            song: song,
            queue: c.uploads,
            onEdit: () => _edit(context, song),
          ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, Song song) async {
    final titleController = TextEditingController(text: song.title);
    final artistController = TextEditingController(text: song.artist);
    var isPublic = song.isPublic;
    var artworkPath = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(c.tr('Chỉnh sửa bài đăng', 'Edit upload')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: c.tr('Tên bài', 'Title'),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: artistController,
                  decoration: InputDecoration(
                    labelText: c.tr('Nghệ sĩ', 'Artist'),
                  ),
                ),
                const SizedBox(height: 10),
                _CoverPickerButton(
                  c: c,
                  selected: artworkPath.isNotEmpty,
                  emptyText: c.tr(
                    'Giữ ảnh bìa hiện tại',
                    'Keep current cover',
                  ),
                  selectedText: c.tr(
                    'Đã chọn ảnh bìa mới',
                    'New cover selected',
                  ),
                  onSelected: (path) {
                    setDialogState(() => artworkPath = path);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isPublic,
                  onChanged: (value) => setDialogState(
                    () => isPublic = value,
                  ),
                  title: Text(c.tr('Công khai', 'Public')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(c.tr('Hủy', 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                c.updateUpload(
                  song,
                  title: titleController.text,
                  artist: artistController.text,
                  isPublic: isPublic,
                  artworkPath: artworkPath,
                );
                Navigator.pop(dialogContext);
              },
              child: Text(c.tr('Lưu', 'Save')),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    artistController.dispose();
  }

  Future<void> _upload(BuildContext context) async {
    final titleController = TextEditingController();
    final artistController = TextEditingController();
    var isPublic = false;
    var artworkPath = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(c.tr('Đăng nhạc', 'Upload music')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: c.tr('Tên bài', 'Title'),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: artistController,
                  decoration: InputDecoration(
                    labelText: c.tr('Nghệ sĩ', 'Artist'),
                  ),
                ),
                const SizedBox(height: 10),
                _CoverPickerButton(
                  c: c,
                  selected: artworkPath.isNotEmpty,
                  emptyText: c.tr('Chọn ảnh bìa', 'Choose cover'),
                  selectedText: c.tr('Đã chọn ảnh bìa', 'Cover selected'),
                  onSelected: (path) {
                    setDialogState(() => artworkPath = path);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isPublic,
                  onChanged: (value) => setDialogState(
                    () => isPublic = value,
                  ),
                  title: Text(c.tr('Công khai', 'Public')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(c.tr('Hủy', 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                c.uploadSong(
                  title: titleController.text,
                  artist: artistController.text,
                  isPublic: isPublic,
                  artworkPath: artworkPath,
                );
              },
              child: Text(c.tr('Chọn file và đăng', 'Choose audio file')),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    artistController.dispose();
  }
}

class _CoverPickerButton extends StatelessWidget {
  const _CoverPickerButton({
    required this.c,
    required this.selected,
    required this.emptyText,
    required this.selectedText,
    required this.onSelected,
  });

  final AppController c;
  final bool selected;
  final String emptyText;
  final String selectedText;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final path = await c.pickUploadCover();
          if (path.isNotEmpty) onSelected(path);
        },
        icon: const Icon(Icons.image_outlined),
        label: Text(
          selected ? selectedText : emptyText,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
