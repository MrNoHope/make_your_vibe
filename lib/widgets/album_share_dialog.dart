import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_colors.dart';
import '../models/playlist.dart';
import 'common_widgets.dart';
import 'share_image_saver.dart';

Future<void> showAlbumShareDialog({
  required BuildContext context,
  required Playlist album,
  required String code,
  required String title,
  required String codeLabel,
  required String savedMessage,
  required String shareText,
  required String subject,
  String? note,
  Future<void> Function()? onStopSharing,
  String? stopMessage,
}) async {
  final shareCardKey = GlobalKey();

  void showSnack(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 24,
        ),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.line),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Đóng',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RepaintBoundary(
                    key: shareCardKey,
                    child: ShareCodeCard(
                      album: album,
                      code: code,
                      label: codeLabel,
                    ),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      note,
                      style: const TextStyle(color: AppColors.soft),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            try {
                              final path = await saveRepaintBoundaryAsPng(
                                boundaryKey: shareCardKey,
                                fileName: 'make_your_vibe_${album.title}_$code',
                              );
                              if (path != null) {
                                showSnack(savedMessage);
                              }
                            } catch (error) {
                              showSnack('$error');
                            }
                          },
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Tải ảnh'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            await SharePlus.instance.share(
                              ShareParams(
                                text: shareText,
                                subject: subject,
                              ),
                            );
                          },
                          icon: const Icon(Icons.send_rounded),
                          label: const Text('Gửi'),
                        ),
                      ),
                    ],
                  ),
                  if (onStopSharing != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          await onStopSharing();
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          showSnack(stopMessage ?? 'Đã ngừng chia sẻ.');
                        } catch (error) {
                          showSnack('$error');
                        }
                      },
                      icon: const Icon(Icons.link_off_rounded),
                      label: const Text('Ngừng chia sẻ'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class ShareCodeCard extends StatelessWidget {
  final Playlist album;
  final String code;
  final String label;

  const ShareCodeCard({
    super.key,
    required this.album,
    required this.code,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = album.subtitle.trim().isEmpty
        ? 'Make Your Vibe'
        : album.subtitle.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFA6F97D),
            AppColors.green,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SizedBox(
        height: 146,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 86,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoverImage(
                    url: album.coverUrl,
                    size: 58,
                    radius: 8,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Make Your Vibe',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  ShareCodeBars(code: code),
                  const SizedBox(height: 8),
                  Text(
                    code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 86,
                height: 86,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  data: code,
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShareCodeBars extends StatelessWidget {
  final String code;

  const ShareCodeBars({
    super.key,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      width: double.infinity,
      child: CustomPaint(
        painter: ShareCodeBarsPainter(code),
      ),
    );
  }
}

class ShareCodeBarsPainter extends CustomPainter {
  final String code;

  const ShareCodeBarsPainter(this.code);

  @override
  void paint(Canvas canvas, Size size) {
    final source = code.trim().isEmpty ? 'make-your-vibe' : code.trim();
    final paint = Paint()..color = Colors.black;
    const bars = 30;
    final step = size.width / bars;
    final width = step * 0.48;

    for (var index = 0; index < bars; index += 1) {
      final unit = source.codeUnitAt(index % source.length);
      final value = (unit + index * 17) % 100;
      final height = size.height * (0.28 + (value / 100) * 0.64);
      final left = index * step + (step - width) / 2;
      final top = (size.height - height) / 2;
      final rect = Rect.fromLTWH(left, top, width, height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(width / 2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ShareCodeBarsPainter oldDelegate) {
    return oldDelegate.code != code;
  }
}
