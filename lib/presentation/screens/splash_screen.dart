import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/notes_repository.dart';
import '../../data/repositories/preferences_repository.dart';
import 'app_shell.dart';

/// Premium animated vector splash screen for iNote.
///
/// Combines a solid brand background, custom-painted vector note mark
/// with realistic paper fold, staggered line-drawing animation,
/// geometric coral accent, and refined "iNote" typography.
class SplashScreen extends StatefulWidget {
  final Widget? nextScreen;
  final Duration minDuration;

  const SplashScreen({
    super.key,
    this.nextScreen,
    this.minDuration = const Duration(milliseconds: 1250),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _foldAnimation;
  late final Animation<double> _line1Animation;
  late final Animation<double> _line2Animation;
  late final Animation<double> _line3Animation;
  late final Animation<double> _accentAnimation;
  late final Animation<double> _titleFadeAnimation;
  late final Animation<Offset> _titleSlideAnimation;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.minDuration,
    );

    // 1. Paper scale & fade
    _scaleAnimation = Tween<double>(begin: 0.84, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    // 2. Corner fold reveal
    _foldAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Staggered writing lines
    _line1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _line2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.48, 0.78, curve: Curves.easeOutCubic),
      ),
    );
    _line3Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    // 4. Accent dot
    _accentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 0.95, curve: Curves.easeOutBack),
      ),
    );

    // 5. Wordmark
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.80, curve: Curves.easeOut),
      ),
    );
    _titleSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.30), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.35, 0.80, curve: Curves.easeOutCubic),
          ),
        );

    _startLaunchSequence();
  }

  Future<void> _startLaunchSequence() async {
    // Run animation and repository initialization concurrently
    final animFuture = _controller.forward();
    final initFuture = _ensureRepositoriesInitialized();

    await Future.wait([animFuture, initFuture]);

    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    // Transition smoothly into the main app shell
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.nextScreen ?? const AppShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  Future<void> _ensureRepositoriesInitialized() async {
    try {
      if (!NotesRepository.instance.isInitialized) {
        await NotesRepository.instance.init();
      }
      if (!PreferencesRepository.instance.isInitialized) {
        await PreferencesRepository.instance.init();
      }
    } catch (e) {
      debugPrint('Initialization error during splash: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Central Vector Mark
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                      child: SizedBox(
                        width: 96,
                        height: 116,
                        child: CustomPaint(
                          painter: NoteVectorMarkPainter(
                            isDark: isDark,
                            foldProgress: _foldAnimation.value,
                            line1Progress: _line1Animation.value,
                            line2Progress: _line2Animation.value,
                            line3Progress: _line3Animation.value,
                            accentProgress: _accentAnimation.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Wordmark "iNote"
                  SlideTransition(
                    position: _titleSlideAnimation,
                    child: FadeTransition(
                      opacity: _titleFadeAnimation,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'i',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: AppColors.primary,
                              ),
                            ),
                            TextSpan(
                              text: 'Note',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.8,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the vector note sheet, dog-ear folded corner,
/// animated writing lines, and geometric coral accent.
class NoteVectorMarkPainter extends CustomPainter {
  final bool isDark;
  final double foldProgress;
  final double line1Progress;
  final double line2Progress;
  final double line3Progress;
  final double accentProgress;

  NoteVectorMarkPainter({
    required this.isDark,
    required this.foldProgress,
    required this.line1Progress,
    required this.line2Progress,
    required this.line3Progress,
    required this.accentProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const radius = 14.0;
    final foldSize = 22.0 * foldProgress;

    // 1. Subtle Paper Drop Shadow
    final shadowPaint = Paint()
      ..color = isDark
          ? Colors.black.withValues(alpha: 0.40)
          : Colors.black.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 5, w, h),
        const Radius.circular(radius),
      ),
      shadowPaint,
    );

    // 2. Base Paper Sheet with Top-Right Fold Cutout
    final paperPath = Path();
    paperPath.moveTo(radius, 0);

    // Top edge to fold start
    paperPath.lineTo(w - foldSize, 0);

    // Fold diagonal edge
    paperPath.lineTo(w, foldSize);

    // Right edge down to bottom right radius
    paperPath.lineTo(w, h - radius);
    paperPath.arcToPoint(
      Offset(w - radius, h),
      radius: const Radius.circular(radius),
    );

    // Bottom edge to bottom left radius
    paperPath.lineTo(radius, h);
    paperPath.arcToPoint(
      Offset(0, h - radius),
      radius: const Radius.circular(radius),
    );

    // Left edge up to top left radius
    paperPath.lineTo(0, radius);
    paperPath.arcToPoint(
      const Offset(radius, 0),
      radius: const Radius.circular(radius),
    );
    paperPath.close();

    // Fill Paper
    final paperFill = Paint()
      ..style = PaintingStyle.fill
      ..color = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface;
    canvas.drawPath(paperPath, paperFill);

    // Border around Paper
    final paperBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = isDark ? const Color(0x33FFFFFF) : const Color(0x18000000);
    canvas.drawPath(paperPath, paperBorder);

    // 3. Folded Corner Flap (Dog-Ear Corner)
    if (foldSize > 1) {
      final flapPath = Path();
      flapPath.moveTo(w - foldSize, 0);
      flapPath.lineTo(w - foldSize, foldSize - 2);
      flapPath.arcToPoint(
        Offset(w - foldSize + 2, foldSize),
        radius: const Radius.circular(2),
      );
      flapPath.lineTo(w, foldSize);
      flapPath.close();

      // Flap shadow
      final flapShadow = Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawPath(flapPath.shift(const Offset(-1, 1)), flapShadow);

      // Flap fill
      final flapFill = Paint()
        ..style = PaintingStyle.fill
        ..color = isDark
            ? AppColors.darkSurfaceHighlight
            : AppColors.lightSurfaceElevated;
      canvas.drawPath(flapPath, flapFill);

      // Flap accent border in primary crimson coral
      final flapBorder = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.primary.withValues(alpha: 0.85);
      canvas.drawPath(flapPath, flapBorder);
    }

    // 4. Staggered Writing Lines
    final leftX = 16.0;
    final lineMaxW = w - 32.0;

    // Line 1 (Header line)
    if (line1Progress > 0) {
      final line1W = (lineMaxW * 0.60) * line1Progress;
      final line1Paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.2
        ..color = isDark
            ? AppColors.darkTextPrimary.withValues(alpha: 0.9)
            : AppColors.lightTextPrimary.withValues(alpha: 0.85);
      canvas.drawLine(
        Offset(leftX, 34),
        Offset(leftX + line1W, 34),
        line1Paint,
      );
    }

    // Line 2 (Body line)
    if (line2Progress > 0) {
      final line2W = (lineMaxW * 0.82) * line2Progress;
      final line2Paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.4
        ..color = isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;
      canvas.drawLine(
        Offset(leftX, 52),
        Offset(leftX + line2W, 52),
        line2Paint,
      );
    }

    // Line 3 (Body line)
    if (line3Progress > 0) {
      final line3W = (lineMaxW * 0.48) * line3Progress;
      final line3Paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.4
        ..color = isDark
            ? AppColors.darkTextTertiary
            : AppColors.lightTextTertiary;
      canvas.drawLine(
        Offset(leftX, 68),
        Offset(leftX + line3W, 68),
        line3Paint,
      );
    }

    // 5. Geometric Accent (Crimson Coral Dot)
    if (accentProgress > 0) {
      final line3EndX = leftX + (lineMaxW * 0.48) + 7;
      final accentPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = AppColors.primary;
      canvas.drawCircle(
        Offset(line3EndX, 68),
        2.6 * accentProgress,
        accentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant NoteVectorMarkPainter oldDelegate) {
    return oldDelegate.foldProgress != foldProgress ||
        oldDelegate.line1Progress != line1Progress ||
        oldDelegate.line2Progress != line2Progress ||
        oldDelegate.line3Progress != line3Progress ||
        oldDelegate.accentProgress != accentProgress ||
        oldDelegate.isDark != isDark;
  }
}
