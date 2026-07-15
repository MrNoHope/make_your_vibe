import 'package:flutter/material.dart';

import '../../app_dependencies.dart';

class AmbientPage extends StatelessWidget {
  const AmbientPage({super.key, required this.c});

  final AppController c;

  @override
  Widget build(BuildContext context) {
    final active = c.ambient.levels.values.where((value) => value > 0).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambient Mixer'),
        actions: [
          IconButton(
            tooltip: c.tr('Dừng tất cả', 'Stop all'),
            onPressed: active == 0 ? null : c.stopAmbient,
            icon: const Icon(Icons.stop_circle_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _saveDialog(context),
        icon: const Icon(Icons.bookmark_add_rounded),
        label: Text(c.tr('Lưu Vibe', 'Save Vibe')),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 112),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.graphic_eq_rounded, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.tr(
                          'Phối không gian âm thanh',
                          'Mix your sound space',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.currentSong == null
                            ? c.tr(
                                'Bật âm thanh bằng công tắc rồi mới chỉnh âm lượng. Cách này tránh kéo nhầm khi cuộn.',
                                'Use the switch first, then adjust volume. This prevents accidental activation while scrolling.',
                              )
                            : c.tr(
                                'Đang phối cùng: ${c.currentSong!.title}',
                                'Mixing with: ${c.currentSong!.title}',
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Chip(label: Text('$active/10')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _MasterVolumeCard(c: c),
          const SizedBox(height: 4),
          for (final item in AmbientGateway.items)
            _AmbientControlCard(c: c, item: item),
        ],
      ),
    );
  }

  Future<void> _saveDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    var isPublic = false;
    var coverPath = '';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(c.tr('Lưu Vibe mới', 'Save new Vibe')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
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
                          ? c.tr('Chọn ảnh Vibe', 'Choose Vibe cover')
                          : c.tr('Đã chọn ảnh Vibe', 'Vibe cover selected'),
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
                c.saveVibe(
                  nameController.text,
                  descriptionController.text,
                  isPublic,
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

class _MasterVolumeCard extends StatefulWidget {
  const _MasterVolumeCard({required this.c});

  final AppController c;

  @override
  State<_MasterVolumeCard> createState() => _MasterVolumeCardState();
}

class _MasterVolumeCardState extends State<_MasterVolumeCard> {
  late double value = widget.c.ambient.masterVolume;
  bool busy = false;

  @override
  void didUpdateWidget(covariant _MasterVolumeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    value = widget.c.ambient.masterVolume;
  }

  Future<void> _setValue(double next) async {
    if (busy) return;
    final safe = next.clamp(0.0, 1.0).toDouble();
    setState(() {
      value = safe;
      busy = true;
    });
    try {
      await widget.c.setAmbientMaster(safe);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _openAdjuster() async {
    var draft = value;
    final result = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.c.tr('Âm lượng tổng', 'Master volume'),
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${(draft * 100).round()}%',
                  style: Theme.of(sheetContext).textTheme.headlineMedium,
                ),
                Slider(
                  value: draft,
                  divisions: 20,
                  label: '${(draft * 100).round()}%',
                  onChanged: (next) => setSheetState(() => draft = next),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, draft),
                    child: Text(widget.c.tr('Áp dụng', 'Apply')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null) await _setValue(result);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.volume_up_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.c.tr('Âm lượng tổng', 'Master volume'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (busy)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    '${(value * 100).round()}%',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: widget.c.tr('Giảm âm lượng', 'Volume down'),
                  onPressed: busy ? null : () => _setValue(value - 0.05),
                  icon: const Icon(Icons.remove_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : _openAdjuster,
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(widget.c.tr('Điều chỉnh', 'Adjust')),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: widget.c.tr('Tăng âm lượng', 'Volume up'),
                  onPressed: busy ? null : () => _setValue(value + 0.05),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientControlCard extends StatefulWidget {
  const _AmbientControlCard({required this.c, required this.item});

  final AppController c;
  final AmbientItem item;

  @override
  State<_AmbientControlCard> createState() => _AmbientControlCardState();
}

class _AmbientControlCardState extends State<_AmbientControlCard> {
  late double value = widget.c.ambient.levels[widget.item.id] ?? 0;
  bool busy = false;

  bool get enabled => value > 0;

  @override
  void didUpdateWidget(covariant _AmbientControlCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    value = widget.c.ambient.levels[widget.item.id] ?? value;
  }

  Future<void> _setValue(double next) async {
    if (busy) return;
    final safe = next.clamp(0.0, 1.0).toDouble();
    setState(() {
      value = safe;
      busy = true;
    });
    try {
      await widget.c.setAmbient(widget.item.id, safe);
    } catch (_) {
      if (!mounted) return;
      setState(() => value = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.c.tr(
              'Không mở được âm thanh này. Hãy thử lại.',
              'This ambient sound could not be opened. Try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _toggle(bool active) => _setValue(active ? 0.55 : 0);

  Future<void> _openAdjuster() async {
    var draft = value;
    final result = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.item.icon, style: const TextStyle(fontSize: 42)),
                const SizedBox(height: 8),
                Text(
                  widget.c.english ? widget.item.en : widget.item.vi,
                  textAlign: TextAlign.center,
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(draft * 100).round()}%',
                  style: Theme.of(sheetContext).textTheme.headlineMedium,
                ),
                Slider(
                  value: draft,
                  divisions: 20,
                  label: '${(draft * 100).round()}%',
                  onChanged: (next) => setSheetState(() => draft = next),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, draft),
                    child: Text(widget.c.tr('Áp dụng', 'Apply')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null) await _setValue(result);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final item = widget.item;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: enabled
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(item.icon, style: const TextStyle(fontSize: 25)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.english ? item.en : item.vi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        enabled
                            ? '${(value * 100).round()}%'
                            : c.tr('Đang tắt', 'Off'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 13),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  Switch(value: enabled, onChanged: _toggle),
              ],
            ),
            if (enabled) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: c.tr('Giảm âm lượng', 'Volume down'),
                    onPressed: busy ? null : () => _setValue(value - 0.05),
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : _openAdjuster,
                      icon: const Icon(Icons.tune_rounded),
                      label: Text(
                        c.tr('Điều chỉnh âm lượng', 'Adjust volume'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: c.tr('Tăng âm lượng', 'Volume up'),
                    onPressed: busy ? null : () => _setValue(value + 0.05),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
