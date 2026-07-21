import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/di/injection.dart';
import '../../domain/usecases/get_level.dart';
import '../bloc/economy/economy_bloc.dart';

/// Cached total level count — loaded once per app session.
int? _cachedTotalLevels;

Future<int> _loadTotalLevels() {
  return _cachedTotalLevels != null
      ? Future.value(_cachedTotalLevels)
      : getIt<GetTotalLevels>()().then((v) {
          _cachedTotalLevels = v;
          return v;
        });
}

/// Scrollable winding path for all levels (1..totalLevels).
class LevelMapView extends StatefulWidget {
  const LevelMapView({
    super.key,
    required this.currentLevel,
    required this.levelStars,
    required this.lives,
    required this.totalLevels,
  });

  final int currentLevel;
  final Map<int, int> levelStars;
  final int lives;
  final int totalLevels;

  @override
  State<LevelMapView> createState() => _LevelMapViewState();
}

class _LevelMapViewState extends State<LevelMapView>
    with AutomaticKeepAliveClientMixin {
  static const double _rowHeight = 72;
  static const double _nodeSize = 56;

  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrent(jump: true);
    });
  }

  @override
  void didUpdateWidget(covariant LevelMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLevel != widget.currentLevel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrent(jump: false);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrent({required bool jump}) {
    if (!mounted || !_scrollController.hasClients) return;
    final target = (widget.currentLevel - 1) * _rowHeight;
    final viewport = _scrollController.position.viewportDimension;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final offset =
        (target - viewport / 2 + _rowHeight / 2).clamp(0.0, maxExtent);

    if (jump) {
      _scrollController.jumpTo(offset);
    } else {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  double _nodeX(int index, double width) {
    return width * (index.isEven ? 0.12 : 0.58);
  }

  void _openLevel(BuildContext context, int level) {
    if (level > widget.currentLevel) return;
    if (widget.lives <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.outOfLives)),
      );
      return;
    }
    context.read<EconomyBloc>().add(const SpendLife());
    context.go('/game/$level');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: widget.totalLevels,
          itemBuilder: (context, index) {
            final level = index + 1;
            final stars = widget.levelStars[level] ?? 0;
            final isCurrent = level == widget.currentLevel;
            final isLocked = level > widget.currentLevel;
            final nodeLeft = _nodeX(index, width);

            return SizedBox(
              height: _rowHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (index > 0)
                    CustomPaint(
                      size: Size(width, _rowHeight),
                      painter: _PathSegmentPainter(
                        fromX: _nodeX(index - 1, width) + _nodeSize / 2,
                        toX: nodeLeft + _nodeSize / 2,
                      ),
                    ),
                  Positioned(
                    left: nodeLeft,
                    top: 8,
                    child: _LevelNode(
                      level: level,
                      stars: stars,
                      isCurrent: isCurrent,
                      isLocked: isLocked,
                      onTap: isLocked ? null : () => _openLevel(context, level),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PathSegmentPainter extends CustomPainter {
  _PathSegmentPainter({
    required this.fromX,
    required this.toX,
  });

  final double fromX;
  final double toX;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neonPurple.withValues(alpha: 0.45)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    const y1 = 0.0;
    final y2 = size.height;
    path.moveTo(fromX, y1);
    path.cubicTo(fromX, y1 + 28, toX, y2 - 28, toX, y2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PathSegmentPainter oldDelegate) =>
      oldDelegate.fromX != fromX || oldDelegate.toX != toX;
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.level,
    required this.stars,
    required this.isCurrent,
    required this.isLocked,
    required this.onTap,
  });

  final int level;
  final int stars;
  final bool isCurrent;
  final bool isLocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCurrent
              ? AppColors.nebulaPurple
              : isLocked
                  ? const Color(0xFF2A2048)
                  : const Color(0xFF1A1040),
          border: Border.all(
            color: isCurrent
                ? AppColors.neonPurple
                : isLocked
                    ? AppColors.border
                    : AppColors.bubbleGlow.withValues(alpha: 0.5),
            width: isCurrent ? 2.5 : 1.5,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppColors.neonPurple.withValues(alpha: 0.5),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLocked)
              const Icon(Icons.lock, size: 16, color: Colors.white38)
            else
              Text(
                '$level',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: level >= 100 ? 11 : 14,
                ),
              ),
            if (stars > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  math.min(stars, 3),
                  (_) => const Icon(
                    Icons.star,
                    size: 8,
                    color: AppColors.neonGold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Loads total level count once, then renders [LevelMapView].
class LevelMapLoader extends StatefulWidget {
  const LevelMapLoader({
    super.key,
    required this.currentLevel,
    required this.levelStars,
    required this.lives,
  });

  final int currentLevel;
  final Map<int, int> levelStars;
  final int lives;

  @override
  State<LevelMapLoader> createState() => _LevelMapLoaderState();
}

class _LevelMapLoaderState extends State<LevelMapLoader>
    with AutomaticKeepAliveClientMixin {
  late final Future<int> _totalLevelsFuture = _loadTotalLevels();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<int>(
      future: _totalLevelsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.neonPurple),
          );
        }
        final total = snapshot.data!;
        return LevelMapView(
          key: const ValueKey('level-map'),
          currentLevel: widget.currentLevel.clamp(1, total),
          levelStars: widget.levelStars,
          lives: widget.lives,
          totalLevels: total,
        );
      },
    );
  }
}
