import 'package:flutter/material.dart';

import '../data/metro_api_v2.dart';
import '../l10n/metro_strings.dart';
import '../../../widget/app_state_views.dart';

// 狀態畫面統一委派給 lib/widget/app_state_views.dart，
// 保留 Metro* 類別名稱與參數，呼叫端不需修改。
class MetroLoadingView extends StatelessWidget {
  const MetroLoadingView({super.key});
  @override
  Widget build(BuildContext context) {
    return AppLoadingView(message: MetroStrings.of(context).loading);
  }
}

class MetroErrorView extends StatelessWidget {
  const MetroErrorView({super.key, required this.kind, required this.onRetry});
  final MetroErrorKind? kind;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = MetroStrings.of(context);
    return AppErrorView(
      message: s.errorMessage(kind),
      onRetry: onRetry,
      retryLabel: s.retry,
    );
  }
}

class MetroEmptyView extends StatelessWidget {
  const MetroEmptyView({super.key, required this.message, this.icon = Icons.search_off_rounded});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppEmptyView(message: message, icon: icon);
  }
}

/// 頂部的小提示列（快取資料、幾何載入失敗等）。
class MetroNoticeBar extends StatelessWidget {
  const MetroNoticeBar({super.key, required this.message, this.actionLabel, this.onAction, this.icon = Icons.info_outline_rounded});
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cs.secondaryContainer,
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSecondaryContainer)),
          ),
          if (actionLabel != null && onAction != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
