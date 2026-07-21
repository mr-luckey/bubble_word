import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import '../constants/app_config.dart';
import '../constants/app_strings.dart';
import '../../core/widgets/app_logo.dart';
import 'update_service.dart';

Future<void> showUpdateDialogIfNeeded(
  BuildContext context,
  UpdateCheckResult result,
) async {
  if (!result.checkSucceeded || !result.updateAvailable) return;
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
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
            AppStrings.updateAvailable,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      content: Text(
        '${AppStrings.updateMessage}\n\n'
        '${AppStrings.currentVersion}: ${result.currentVersion}\n'
        '${AppStrings.storeVersion}: ${result.storeVersion}',
        style: GoogleFonts.nunito(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(AppStrings.notNow),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final url = Theme.of(ctx).platform == TargetPlatform.iOS
                ? AppConfig.iosStoreUrl
                : AppConfig.androidStoreUrl;
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Text(AppStrings.updateNow),
        ),
      ],
    ),
  );
}
