import 'package:flutter/material.dart';

import '../data/metro_api_v2.dart';
import '../l10n/metro_strings.dart';

class MetroLoadingView extends StatelessWidget {
  const MetroLoadingView({super.key});
  @override
  Widget build(BuildContext context) {
    final s = MetroStrings.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(s.loading, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class MetroErrorView extends StatelessWidget {
  const MetroErrorView({super.key, required this.kind, required this.onRetry});
  final MetroErrorKind? kind;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = MetroStrings.of(context);
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(s.errorMessage(kind), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: Text(s.retry)),
          ],
        ),
      ),
    );
  }
}

class MetroEmptyView extends StatelessWidget {
  const MetroEmptyView({super.key, required this.message, this.icon = Icons.search_off_rounded});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
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
