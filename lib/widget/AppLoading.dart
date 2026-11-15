import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

/// 通用載入動畫元件（支援深色模式）
class AppLoading extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLoading({
    super.key,
    this.size = 40.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // 未指定顏色時，預設在深色模式顯示白色，淺色模式顯示黑色
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Center(
      child: reducedMotion
          ? SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                color: effectiveColor,
                strokeWidth: 3,
              ),
            )
          : LoadingAnimationWidget.stretchedDots(
              color: effectiveColor,
              size: size,
            ),
    );
  }
}
