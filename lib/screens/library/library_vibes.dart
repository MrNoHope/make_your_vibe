import 'dart:io';

import 'package:flutter/material.dart';

import '../../app_dependencies.dart';

class LibraryVibes extends StatelessWidget {
  const LibraryVibes({required this.c});

  final AppController c;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (c.vibes.isEmpty)
          EmptyState(
            icon: Icons.auto_awesome,
            text: c.tr('Chưa có Vibe đã lưu.', 'No saved Vibes yet.'),
          ),
        for (final vibe in c.vibes)
          Card(
            child: ListTile(
              leading: VibeCover(path: vibe.coverPath),
              title: Text(
                vibe.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                vibe.description.isEmpty
                    ? '${vibe.levels.values.where((value) => value > 0).length} ambient'
                    : vibe.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => c.applyVibe(vibe),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'apply') c.applyVibe(vibe);
                  if (value == 'edit') _edit(context, vibe);
                  if (value == 'share') {
                    c.shareText(
                      'Make Your Vibe: ${vibe.name} - ${vibe.description}',
                    );
                  }
                  if (value == 'delete') c.deleteVibe(vibe);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'apply',
                    child: Text(c.tr('Áp dụng', 'Apply')),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(c.tr('Chỉnh sửa', 'Edit')),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Text(c.tr('Chia sẻ', 'Share')),
                  ),
                  if (!vibe.id.startsWith('sample_'))
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(c.tr('Xóa', 'Delete')),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, VibePreset vibe) async {
    final nameController = TextEditingController(text: vibe.name);
    final descriptionController = TextEditingController(
      text: vibe.description,
    );
    var isPublic = vibe.isPublic;
    var coverPath = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(c.tr('Chỉnh sửa Vibe', 'Edit Vibe')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: c.tr('Tên Vibe', 'Vibe name'),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: c.tr('Mô tả', 'Description'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await c.pickVibeCover();
                      if (selected.isNotEmpty) {
                        setDialogState(() => coverPath = selected);
                      }
                    },
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      coverPath.isEmpty
                          ? c.tr(
                              'Giữ ảnh Vibe hiện tại',
                              'Keep current cover',
                            )
                          : c.tr(
                              'Đã chọn ảnh Vibe mới',
                              'New cover selected',
                            ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
                c.updateVibe(
                  vibe,
                  name: nameController.text,
                  description: descriptionController.text,
                  isPublic: isPublic,
                  coverPath: coverPath,
                );
                Navigator.pop(dialogContext);
              },
              child: Text(c.tr('Lưu', 'Save')),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    descriptionController.dispose();
  }
}

class VibeCover extends StatelessWidget {
  const VibeCover({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final file = path.isEmpty ? null : File(path);
    if (file != null && file.existsSync()) {
      return CircleAvatar(backgroundImage: FileImage(file));
    }
    return const CircleAvatar(child: Icon(Icons.auto_awesome));
  }
}
