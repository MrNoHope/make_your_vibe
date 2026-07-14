import 'package:flutter/material.dart';

import '../controllers/vibe_controller.dart';
import '../core/app_colors.dart';
import '../models/ambient_layer.dart';

class AmbientTile extends StatelessWidget {
  const AmbientTile({
    super.key,
    required this.layer,
    required this.onTap,
  });

  final AmbientLayer layer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = layer.active ? AppColors.green : Colors.white70;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: layer.active ? AppColors.green.withOpacity(0.14) : AppColors.panel,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: layer.active ? AppColors.green : AppColors.line,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(layer.icon, color: color, size: 31),
            const Spacer(),
            Text(
              layer.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              layer.active ? 'ACTIVE' : 'TAP TO ADD',
              style: TextStyle(
                color: layer.active ? AppColors.green : AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AmbientCompactTile extends StatelessWidget {
  const AmbientCompactTile({
    super.key,
    required this.layer,
    required this.onTap,
  });

  final AmbientLayer layer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: layer.active ? AppColors.green : AppColors.line,
        ),
      ),
      tileColor: layer.active ? AppColors.green.withOpacity(0.14) : AppColors.panel,
      leading: Icon(
        layer.icon,
        color: layer.active ? AppColors.green : Colors.white70,
      ),
      title: Text(
        layer.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(layer.group),
    );
  }
}

class AmbientBanner extends StatelessWidget {
  const AmbientBanner({
    super.key,
    required this.controller,
    required this.onTap,
  });

  final VibeController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.spa, color: AppColors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ÂM NỀN',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    controller.activeLayerText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_up),
          ],
        ),
      ),
    );
  }
}

class MixerRow extends StatelessWidget {
  const MixerRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.active = true,
    this.onToggle,
  });

  final IconData icon;
  final String title;
  final double value;
  final bool active;
  final ValueChanged<double> onChanged;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onToggle,
          icon: Icon(
            icon,
            color: active ? AppColors.green : Colors.white38,
          ),
        ),
        SizedBox(
          width: 112,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 1,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 42,
          child: Text(
            '${(value * 100).round()}%',
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
