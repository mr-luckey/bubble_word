import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

Future<bool> showQuitGameDialog(BuildContext context) {
  return _showQuitDialog(
    context,
    title: AppStrings.quitGameTitle,
    message: AppStrings.quitGameMessage,
  );
}

Future<bool> showQuitAppDialog(BuildContext context) {
  return _showQuitDialog(
    context,
    title: AppStrings.quitAppTitle,
    message: AppStrings.quitAppMessage,
  );
}

Future<bool> _showQuitDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1040),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.neonPurple, width: 2),
      ),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Text(
        message,
        style: GoogleFonts.nunito(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(AppStrings.quit),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> exitApp() async {
  await SystemNavigator.pop();
}
