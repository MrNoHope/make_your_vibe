import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class PageScroll extends StatelessWidget {
  final Widget child;

  const PageScroll({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      children: [
        child,
      ],
    );
  }
}

class TopBar extends StatelessWidget {
  final String title;
  final Widget? action;

  const TopBar({
    super.key,
    required this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        action ??
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_horiz_rounded),
            ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null && onTap != null)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(99),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              child: Text(
                action!,
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class SmallGreenButton extends StatelessWidget {
  final String label;

  const SmallGreenButton({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class CoverImage extends StatelessWidget {
  final String url;
  final double size;
  final double radius;

  const CoverImage({
    super.key,
    required this.url,
    required this.size,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: AppColors.darkGradient,
        border: Border.all(color: AppColors.line),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: AppColors.green,
          size: size == double.infinity ? 40 : size * 0.34,
        ),
      ),
    );

    final child = url.trim().isEmpty
        ? fallback
        : ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              cacheWidth: size == double.infinity
                  ? null
                  : (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
              cacheHeight: size == double.infinity
                  ? null
                  : (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }

                return fallback;
              },
              errorBuilder: (_, __, ___) => fallback,
            ),
          );

    if (size == double.infinity) {
      return child;
    }

    return SizedBox(
      width: size,
      height: size,
      child: child,
    );
  }
}

class AlbumBox extends StatelessWidget {
  final double size;

  const AlbumBox({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return CoverImage(url: '', size: size);
  }
}

class BackendNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const BackendNotice({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.green,
            size: 32,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.soft,
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
