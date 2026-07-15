import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/ambient_layer.dart';
import '../../services/ambient_audio_gateway.dart';
import '../../widgets/common_widgets.dart';

class SoundEffectsPage extends StatelessWidget {
  const SoundEffectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambientAudioGateway,
      builder: (context, _) {
        final gateway = ambientAudioGateway;

        return PageScroll(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopBar(
                title: 'Âm thanh nền',
                action: IconButton(
                  tooltip: 'Dừng tất cả',
                  onPressed: gateway.activeCount == 0 ? null : gateway.stopAll,
                  icon: const Icon(Icons.stop_circle_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.graphic_eq_rounded,
                        color: AppColors.green,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phối không gian âm thanh',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Bật từng âm thanh rồi điều chỉnh âm lượng để phối cùng bài hát đang nghe.',
                            style: TextStyle(
                              color: AppColors.soft,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.panel2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${gateway.activeCount}/${gateway.layers.length}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
              if (gateway.errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                BackendNotice(
                  icon: Icons.error_outline_rounded,
                  title: 'Không phát được âm thanh nền',
                  message: gateway.errorMessage,
                ),
              ],
              const SizedBox(height: 12),
              _MasterVolumeCard(gateway: gateway),
              const SizedBox(height: 8),
              for (final layer in gateway.layers)
                _AmbientControlCard(
                  key: ValueKey(layer.id),
                  gateway: gateway,
                  layer: layer,
                ),
              const SizedBox(height: 90),
            ],
          ),
        );
      },
    );
  }
}

class _MasterVolumeCard extends StatefulWidget {
  final AmbientAudioGateway gateway;

  const _MasterVolumeCard({required this.gateway});

  @override
  State<_MasterVolumeCard> createState() => _MasterVolumeCardState();
}

class _MasterVolumeCardState extends State<_MasterVolumeCard> {
  late double value = widget.gateway.masterVolume;
  bool busy = false;

  @override
  void didUpdateWidget(covariant _MasterVolumeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    value = widget.gateway.masterVolume;
  }

  Future<void> _setValue(double next) async {
    if (busy) return;
    final safe = next.clamp(0.0, 1.0).toDouble();
    setState(() {
      value = safe;
      busy = true;
    });
    try {
      await widget.gateway.setMasterVolume(safe);
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
                const Text(
                  'Âm lượng tổng',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
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
                    child: const Text('Áp dụng'),
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
      margin: EdgeInsets.zero,
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.volume_up_rounded, color: AppColors.green),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Âm lượng tổng',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                if (busy)
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    '${(value * 100).round()}%',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Giảm âm lượng',
                  onPressed: busy ? null : () => _setValue(value - 0.05),
                  icon: const Icon(Icons.remove_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : _openAdjuster,
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Điều chỉnh'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Tăng âm lượng',
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
  final AmbientAudioGateway gateway;
  final AmbientLayer layer;

  const _AmbientControlCard({
    super.key,
    required this.gateway,
    required this.layer,
  });

  @override
  State<_AmbientControlCard> createState() => _AmbientControlCardState();
}

class _AmbientControlCardState extends State<_AmbientControlCard> {
  late double value = widget.layer.volume;
  bool busy = false;

  @override
  void didUpdateWidget(covariant _AmbientControlCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    value = widget.layer.volume;
  }

  Future<void> _setValue(double next) async {
    if (busy) return;
    final safe = next.clamp(0.0, 1.0).toDouble();
    setState(() {
      value = safe;
      busy = true;
    });
    try {
      await widget.gateway.setLayerVolume(widget.layer.id, safe);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _toggle(bool active) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await widget.gateway.setLayerActive(widget.layer.id, active);
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
                Icon(
                  _ambientIcon(widget.layer.id),
                  color: AppColors.green,
                  size: 42,
                ),
                const SizedBox(height: 8),
                Text(
                  _ambientName(widget.layer.id),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
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
                    child: const Text('Áp dụng'),
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
    final active = widget.layer.active;
    final loading = widget.gateway.isLoading(widget.layer.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: active ? AppColors.green : AppColors.line,
        ),
      ),
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
                    color: active
                        ? AppColors.green.withValues(alpha: 0.16)
                        : AppColors.panel2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _ambientIcon(widget.layer.id),
                    color: AppColors.green,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _ambientName(widget.layer.id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        active ? '${(value * 100).round()}%' : 'Đang tắt',
                        style: const TextStyle(
                          color: AppColors.soft,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (busy || loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 13),
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  Switch(value: active, onChanged: _toggle),
              ],
            ),
            if (active) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Giảm âm lượng',
                    onPressed: busy ? null : () => _setValue(value - 0.05),
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : _openAdjuster,
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text(
                        'Điều chỉnh âm lượng',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Tăng âm lượng',
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

String _ambientName(String id) {
  return switch (id) {
    'cricket_sound' => 'Tiếng dế',
    'night_cricket_sound' => 'Dế ban đêm',
    'hard_fire' => 'Lửa lớn',
    'soft_fire' => 'Lửa nhẹ',
    'hard_rain' => 'Mưa lớn',
    'soft_rain' => 'Mưa nhẹ',
    'ocean_waves' => 'Sóng biển',
    'ocean_waves_smooth' => 'Sóng biển êm',
    'smooth_brown_noise' => 'Brown noise êm',
    'soft_brown_noise' => 'Brown noise nhẹ',
    _ => id,
  };
}

IconData _ambientIcon(String id) {
  return switch (id) {
    'cricket_sound' => Icons.grass_rounded,
    'night_cricket_sound' => Icons.nightlight_round,
    'hard_fire' || 'soft_fire' => Icons.local_fire_department_rounded,
    'hard_rain' || 'soft_rain' => Icons.water_drop_rounded,
    'ocean_waves' || 'ocean_waves_smooth' => Icons.waves_rounded,
    'smooth_brown_noise' || 'soft_brown_noise' => Icons.headphones_rounded,
    _ => Icons.graphic_eq_rounded,
  };
}
