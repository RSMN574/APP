import 'package:flutter/material.dart';

import '../const/app_colors.dart';
import '../const/app_design_tokens.dart';
import '../l10n/app_localizations.dart';
import 'AppLoading.dart';

/// 全 App 共用的載入 / 空資料 / 錯誤狀態元件。
///
/// 各 Feature 只需提供文字與動作，外觀（圖示尺寸、間距、字級、顏色）
/// 統一由這裡決定，並自動支援深淺色、字體縮放與 TalkBack。

/// 載入中狀態。[message] 會同時作為螢幕閱讀器的朗讀文字。
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      liveRegion: true,
      label: message,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ExcludeSemantics(child: AppLoading()),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.lg),
                ExcludeSemantics(
                  child: Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTypography.bodyMedium,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 沒有資料時的狀態。
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String message;
  final String? title;
  final IconData icon;

  /// 選用的動作按鈕，例如「重新整理」。
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return _StateLayout(
      icon: icon,
      iconColor: context.appColors.textHint,
      title: title,
      message: message,
      action: action,
    );
  }
}

/// 錯誤狀態；提供 [onRetry] 時顯示重試按鈕。
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.cloud_off_rounded,
    this.onRetry,
    this.retryLabel,
  });

  final String message;
  final String? title;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return _StateLayout(
      icon: icon,
      iconColor: context.appColors.danger,
      title: title,
      message: message,
      action: onRetry == null
          ? null
          : FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                retryLabel ?? AppLocalizations.of(context)?.text_420 ?? 'Retry',
              ),
            ),
    );
  }
}

class _StateLayout extends StatelessWidget {
  const _StateLayout({
    required this.icon,
    required this.iconColor,
    required this.message,
    this.title,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String? title;
  final String message;
  final Widget? action;

  static const double _iconContainerSize = 72;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      // 字體放大時內容可能超出可視高度，允許捲動避免溢出。
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: _iconContainerSize,
                height: _iconContainerSize,
                decoration: BoxDecoration(
                  color: colors.mutedBackground,
                  borderRadius: AppRadius.roundedXl,
                ),
                child: Icon(icon, size: 36, color: iconColor),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTypography.titleMedium,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTypography.bodyMedium,
                height: AppTypography.bodyHeight,
                color: colors.textSecondary,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
