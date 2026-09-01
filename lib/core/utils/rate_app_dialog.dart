import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../di/injection.dart';
import '../widgets/app_logo.dart';
import 'rate_app_service.dart';

enum _RateDialogAction { rate, later, never }

Future<void> showRateAppDialog(BuildContext context) async {
  final rateService = getIt<RateAppService>();
  await rateService.markPromptShown();

  if (!context.mounted) return;

  final action = await showDialog<_RateDialogAction>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1040),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.neonPurple, width: 2),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogo(size: 64),
          const SizedBox(height: 12),
          Text(
            AppStrings.rateAppTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      content: Text(
        AppStrings.rateAppMessage,
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, _RateDialogAction.never),
          child: Text(AppStrings.noThanks),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, _RateDialogAction.later),
          child: Text(AppStrings.maybeLater),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, _RateDialogAction.rate),
          child: Text(AppStrings.rateNow),
        ),
      ],
    ),
  );

  switch (action) {
    case _RateDialogAction.rate:
      await rateService.markRated();
      if (context.mounted) {
        final ok = await rateService.requestReview();
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.rateAppUnavailable)),
          );
        }
      }
    case _RateDialogAction.never:
      await rateService.markDismissed();
    case _RateDialogAction.later:
    case null:
      break;
  }
}
