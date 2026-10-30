import 'package:flutter/material.dart';

/// 全專案統一的自訂 AppBar 樣式。
class AppCustomBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final bool showDecoration;

  const AppCustomBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.bottom,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
    this.showDecoration = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final appBar = AppBar(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      leading: automaticallyImplyLeading
          ? (leading ?? _defaultLeadingButton(context, colorScheme))
          : leading,
      title: titleWidget ??
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
              letterSpacing: -0.35,
            ),
          ),
      actions: actions,
      bottom: bottom,
    );

    if (!showDecoration) {
      return appBar;
    }

    // 關鍵：用 Size.fromHeight 限制外層 Container 高度，避免被 Stack 撐開
    return SizedBox(
      height: 200,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),

        ),
        child: Stack(
          children: [
            Positioned.fill(child: appBar),
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.45,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _defaultLeadingButton(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: colorScheme.primary,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

/// AppBar actions 通用按鈕：與頁面中的 `Container + IconButton` 樣式完全一致。
Widget appBarActionButton({
  required BuildContext context,
  required IconData icon,
  required VoidCallback onPressed,
  String? tooltip,
  double size = 20,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return Container(
    margin: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: size),
      color: colorScheme.primary,
      onPressed: onPressed,
    ),
  );
}