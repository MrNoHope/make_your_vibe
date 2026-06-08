import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_texts.dart';
import '../../../core/controllers/app_locale_controller.dart';

class LanguageSettingsSheet extends StatelessWidget {
  const LanguageSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final localeController = context.watch<AppLocaleController>();
    final language = localeController.currentLanguage;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppTexts.languageTitle(language),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _LanguageTile(
              title: AppTexts.vietnamese(language),
              active: language == AppLanguage.vi,
              onTap: () {
                localeController.changeLanguage(AppLanguage.vi);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _LanguageTile(
              title: AppTexts.english(language),
              active: language == AppLanguage.en,
              onTap: () {
                localeController.changeLanguage(AppLanguage.en);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.spotifyGreen : AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (active)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                ),
            ],
          ),
        ),
      ),
    );
  }
}