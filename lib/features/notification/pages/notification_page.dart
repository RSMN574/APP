import 'package:flutter/material.dart';
import 'package:com.rsmn574.app/features/notification/state/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, String>> get notifications => context
      .watch<NotificationProvider>()
      .items
      .map((item) => item.toMap())
      .toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationProvider>().load();
    });
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.text_435,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.primary),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, size: 24),
            onPressed: () => _showMoreOptions(),
          ),
        ],
      ),
      body: context.watch<NotificationProvider>().state.isLoading &&
              notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? _buildEmptyState(context)
          : _buildNotificationList(),
    );
  }

  Widget _buildEmptyState(context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 60,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              AppLocalizations.of(context)!.text_436,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.text_437,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                AppLocalizations.of(context)!.text_438,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    return Column(
      children: [
        // 標題欄
        _buildHeader(),
        const SizedBox(height: 8),
        // 通知列表
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.filter_list_rounded,
              size: 20,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context as BuildContext)!.text_439,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            '${notifications.length} 則通知',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUnread = notification['read'] == false;
    final notificationType = notification['type'] ?? 'info';

    return Transform.translate(
      offset: Offset(0, index * 0.5), // 微妙的層次感
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(20),
          splashColor: colorScheme.primary.withValues(alpha: 0.1),
          highlightColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
          child: Container(
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow
                      .withValues(alpha: isUnread ? 0.1 : 0.05),
                  blurRadius: isUnread ? 20 : 12,
                  offset: Offset(0, isUnread ? 6 : 3),
                ),
              ],
              border: isUnread
                  ? Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                // 左側裝飾線
                if (isUnread)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: EdgeInsets.only(
                    left: isUnread ? 20 : 24,
                    right: 24,
                    top: 20,
                    bottom: 20,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 圖標區域
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: _getNotificationGradient(notificationType),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _getNotificationColor(notificationType)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getNotificationIcon(notificationType),
                          size: 24,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // 內容區域
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 標題和時間
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification['title']!,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: isUnread
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurfaceVariant,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    notification['time']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // 描述
                            Text(
                              notification['description']!,
                              style: TextStyle(
                                fontSize: 15,
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // 標籤和操作
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // 類型標籤
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        _getNotificationColor(notificationType)
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getNotificationColor(
                                              notificationType)
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    _getNotificationTypeText(notificationType),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getNotificationColor(
                                          notificationType),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // 未讀標記
                                if (isUnread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _getNotificationGradient(String type) {
    final color = _getNotificationColor(type);
    return LinearGradient(
      colors: [
        color,
        color.withOpacity(0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'warning':
        return const Color(0xFFFF9500);
      case 'error':
        return Theme.of(context).colorScheme.error;
      case 'success':
        return const Color(0xFF34C759);
      case 'promotion':
        return const Color(0xFFAF52DE);
      case 'info':
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'error':
        return Icons.error_outline_rounded;
      case 'success':
        return Icons.check_circle_outline_rounded;
      case 'promotion':
        return Icons.local_offer_rounded;
      case 'info':
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _getNotificationTypeText(String type) {
    switch (type) {
      case 'warning':
        return AppLocalizations.of(context as BuildContext)!.text_440;
      case 'error':
        return AppLocalizations.of(context as BuildContext)!.text_441;
      case 'success':
        return AppLocalizations.of(context as BuildContext)!.text_442;
      case 'promotion':
        return AppLocalizations.of(context as BuildContext)!.text_443;
      case 'info':
      default:
        return AppLocalizations.of(context as BuildContext)!.text_444;
    }
  }

  void _showMoreOptions() {
    // 顯示更多選項
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // 處理通知點擊
  }
}
