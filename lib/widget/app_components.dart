import 'package:flutter/material.dart';

import '../const/app_colors.dart';
import '../const/app_design_tokens.dart';

/// 全 App 共用的基礎元件（docs/design_system.md §7）。
///
/// 只封裝「各頁重複實作」的樣式；按鈕、輸入框、ListTile 直接使用 Material
/// 元件 + Theme，不另外包裝。

/// 卡片：卡片底色、圓角 20、輕陰影、可選點擊。
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.margin = EdgeInsets.zero,
    this.radius = AppRadius.xl,
    this.color,
    this.outlined = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final Color? color;

  /// 以 1dp 邊框取代陰影（用於在卡片內再放卡片時）。
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: outlined
          ? BorderSide(color: c.border, width: AppSizes.borderWidth)
          : BorderSide.none,
    );
    return Padding(
      padding: margin,
      child: Material(
        color: color ?? c.cardBackground,
        shape: shape,
        elevation: 0,
        shadowColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: outlined
                ? null
                : [
                    BoxShadow(
                        color: c.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

enum AppIconTone { primary, muted, tertiary, danger }

/// 圖示容器：首頁交通入口（圓形 56）與 AppBar / 列表圖示（圓角方形 48）。
class AppIconContainer extends StatelessWidget {
  const AppIconContainer({
    super.key,
    required this.child,
    this.size = AppSizes.iconContainer,
    this.circle = false,
    this.tone = AppIconTone.primary,
    this.onTap,
    this.tooltip,
  });

  /// 一般為 `Icon` 或 `SvgPicture`；顏色請使用 [AppIconContainer.foregroundOf]。
  final Widget child;
  final double size;
  final bool circle;
  final AppIconTone tone;
  final VoidCallback? onTap;
  final String? tooltip;

  static Color foregroundOf(BuildContext context, AppIconTone tone) {
    final scheme = Theme.of(context).colorScheme;
    return switch (tone) {
      AppIconTone.primary => scheme.primary,
      AppIconTone.muted => scheme.onSurfaceVariant,
      AppIconTone.tertiary => scheme.tertiary,
      AppIconTone.danger => scheme.error,
    };
  }

  static Color backgroundOf(BuildContext context, AppIconTone tone) {
    final scheme = Theme.of(context).colorScheme;
    return switch (tone) {
      AppIconTone.danger => context.appColors.dangerContainer,
      AppIconTone.tertiary => scheme.tertiary.withValues(alpha: 0.12),
      _ => scheme.surfaceContainerHighest,
    };
  }

  @override
  Widget build(BuildContext context) {
    final radius = circle
        ? BorderRadius.circular(AppRadius.full)
        : BorderRadius.circular(AppRadius.md);
    Widget box = Material(
      color: backgroundOf(context, tone),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: IconTheme.merge(
              data: IconThemeData(
                color: foregroundOf(context, tone),
                size: AppSizes.iconLg,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
    if (tooltip != null) box = Tooltip(message: tooltip!, child: box);
    return box;
  }
}

/// 區塊標題：左側標題、可選右側動作。
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.pageMargin,
      AppSpacing.xl,
      AppSpacing.pageMargin,
      AppSpacing.sm,
    ),
  });

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 搜尋框：Theme 的 InputDecoration + 搜尋圖示與清除按鈕。
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip:
                      MaterialLocalizations.of(context).deleteButtonTooltip,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                ),
        ),
      ),
    );
  }
}

/// 統一 Dialog（取代不受 Theme 控制的 quickalert）。
Future<bool?> showAppDialog(
  BuildContext context, {
  required String title,
  String? message,
  Widget? content,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  final l10n = MaterialLocalizations.of(context);
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: content ?? (message == null ? null : Text(message)),
      actions: [
        if (cancelLabel != null || confirmLabel != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel ?? l10n.cancelButtonLabel),
          ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel ?? l10n.okButtonLabel),
        ),
      ],
    ),
  );
}

/// 統一 BottomSheet：安全區、拖曳把手與 Theme 底色。
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: isScrollControlled,
    builder: builder,
  );
}
