import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../theme/reference_theme.dart';
import '../utils/word_visuals.dart';
import '../../domain/entities/level.dart';
import 'marquee_light_border.dart';

/// "FIND 3 FRUITS" panel — festive marquee + word pills (reference).
class TargetWordsPanel extends StatelessWidget {
  const TargetWordsPanel({
    super.key,
    required this.level,
    required this.completedWordIds,
  });

  final Level level;
  final List<String> completedWordIds;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        0,
        AppDimensions.paddingM,
        4,
      ),
      child: MarqueeLightBorder(
        borderRadius: 14,
        bulbSize: 3,
        bulbSpacing: 8,
        padding: 3,
        frameBorderWidth: 2.5,
        bulbPalette: ReferenceTheme.festiveBulbs,
        duration: const Duration(milliseconds: 1800),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _HintTitle(hint: level.hint),
            const SizedBox(height: 6),
            SizedBox(
              height: 32,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < level.words.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _WordPill(
                        text: level.words[i].text,
                        isComplete:
                            completedWordIds.contains(level.words[i].id),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HintTitle extends StatelessWidget {
  const _HintTitle({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    final upper = hint.toUpperCase();
    final match = RegExp(r'(\d+)').firstMatch(upper);

    if (match == null) {
      return Text(
        upper,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.nunito(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      );
    }

    final number = match.group(0)!;
    final before = upper.substring(0, match.start);
    final after = upper.substring(match.end);

    return RichText(
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: GoogleFonts.nunito(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: number,
            style: const TextStyle(color: ReferenceTheme.gold),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}

class _WordPill extends StatelessWidget {
  const _WordPill({required this.text, required this.isComplete});

  final String text;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final textColor = isComplete
        ? AppColors.accentGreen
        : WordVisuals.textColor(text);

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isComplete
              ? AppColors.accentGreen.withValues(alpha: 0.7)
              : const Color(0xFFE8E8E8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          WordMiniIcon(word: text, size: 18),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: GoogleFonts.nunito(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.6,
              decoration: isComplete ? TextDecoration.lineThrough : null,
              decorationColor: AppColors.accentGreen,
              decorationThickness: 2.5,
            ),
          ),
        ],
      ),
    );
  }
}
