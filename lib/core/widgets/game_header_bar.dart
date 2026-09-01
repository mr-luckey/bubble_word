import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_dimensions.dart';
import '../theme/reference_theme.dart';
import 'marquee_light_border.dart';

/// Reference header — back, wide LEVEL marquee, timer + hint marquees.
class GameHeaderBar extends StatelessWidget {
  const GameHeaderBar({
    super.key,
    required this.levelId,
    required this.timeLeftSeconds,
    this.onBack,
    this.onHint,
    this.hintCount = 0,
  });

  final int levelId;
  final int timeLeftSeconds;
  final VoidCallback? onBack;
  final VoidCallback? onHint;
  final int hintCount;

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isLowTime = timeLeftSeconds <= 10;
    final accent = isLowTime ? const Color(0xFFEF476F) : ReferenceTheme.gold;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        4,
        AppDimensions.paddingM,
        2,
      ),
      child: Row(
        children: [
          if (onBack != null) _BackButton(onTap: onBack!),
          const SizedBox(width: 6),
          Expanded(
            child: MarqueeLightBorder(
              borderRadius: 12,
              bulbSize: 2.8,
              bulbSpacing: 7.5,
              padding: 2,
              frameBorderWidth: 2,
              duration: const Duration(milliseconds: 1500),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  'LEVEL $levelId',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _MarqueeStatChip(
            onTap: null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time_rounded, color: accent, size: 15),
                const SizedBox(width: 3),
                Text(
                  _formatTime(timeLeftSeconds),
                  style: GoogleFonts.nunito(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onHint != null) ...[
            const SizedBox(width: 5),
            _MarqueeStatChip(
              onTap: onHint,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$hintCount',
                    style: GoogleFonts.nunito(
                      color: ReferenceTheme.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.lightbulb_rounded,
                    color: ReferenceTheme.gold,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ReferenceTheme.panelPurple,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ReferenceTheme.goldBorder, width: 2),
            boxShadow: [
              BoxShadow(
                color: ReferenceTheme.goldDeep.withValues(alpha: 0.35),
                blurRadius: 6,
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _MarqueeStatChip extends StatelessWidget {
  const _MarqueeStatChip({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: MarqueeLightBorder(
          borderRadius: 10,
          bulbSize: 2.5,
          bulbSpacing: 7,
          padding: 1,
          frameBorderWidth: 1.8,
          duration: const Duration(milliseconds: 1600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: child,
          ),
        ),
      ),
    );
  }
}
