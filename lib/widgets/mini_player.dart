import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'common_widgets.dart';

class MiniPlayerBar extends StatelessWidget {
  final VoidCallback onTap;

  const MiniPlayerBar({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background2,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 58,
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.line),
            ),
          ),
          child: Row(
            children: [
              const AlbumBox(size: 42),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Music backend pending',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'No fake song loaded',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onTap,
                icon: const Icon(
                  Icons.play_circle_fill_rounded,
                  color: AppColors.green,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}