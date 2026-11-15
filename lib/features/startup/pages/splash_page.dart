import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const _brandBlue = Color(0xFF1677FF);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF071A36), Color(0xFF102B4C)]
                : const [Color(0xFFF3F8FF), Color(0xFFE7F8F5)],
          ),
        ),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.82, end: 1),
            duration: reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (context, opacity, child) => Opacity(
                opacity: opacity,
                child: child,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BrandMark(isDark: isDark),
                  const SizedBox(height: 24),
                  Text(
                    '台灣通',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Taiwan Pass',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textColor.withValues(alpha: 0.68),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 34),
                  SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      semanticsLabel: '正在載入台灣通',
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(3),
                      backgroundColor: textColor.withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation(_brandBlue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF123866) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF1677FF).withValues(alpha: isDark ? 0.2 : 0.14),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF1677FF), Color(0xFF00B8A9)],
              ),
            ),
          ),
          const Icon(
            Icons.alt_route_rounded,
            color: Colors.white,
            size: 40,
          ),
          Positioned(
            right: 18,
            top: 18,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFFFC857),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
