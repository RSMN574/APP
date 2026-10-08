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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 未指定顏色時，預設在深色模式顯示白色，淺色模式顯示黑色
    final effectiveColor = color ?? (isDark ? Colors.white : Colors.black);

    return Center(
      child: LoadingAnimationWidget.stretchedDots(
        color: effectiveColor,
        size: size,
      ),
    );
  }
}