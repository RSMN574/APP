import 'package:com.rsmn574.app/features/notification/services/arrival_reminder_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:com.rsmn574.app/features/diagnostics/pages/diagnostics_page.dart';
import 'package:com.rsmn574.app/firebase/fcm.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:com.rsmn574.app/features/profile/pages/taiwan_cities_page.dart';
import 'package:com.rsmn574.app/features/mileage/pages/mileage_page.dart';
import 'package:com.rsmn574.app/features/auth/state/auth_provider.dart';
import 'package:com.rsmn574.app/features/settings/pages/settings_page.dart';
import 'package:com.rsmn574.app/const/app_colors.dart';

class InfoPages extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;

    final displayName = user == null
        ? l10n.authGuestAccount
        : (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!
        : (user.email ?? l10n.profileUnknown);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ==================== 用戶資料卡片 ====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 用戶頭像 + 資訊（點擊進入個人資料／登入）
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.of(context).pushNamed(
                          user == null ? '/auth/login' : '/auth/profile',
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colors.info,
                                    colors.info.withValues(alpha: 0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: user?.photoURL == null
                                  ? const Icon(
                                Icons.person_rounded,
                                size: 30,
                                color: Colors.white,
                              )
                                  : Image.network(
                                user!.photoURL!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person_rounded,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: colors.info,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user == null
                                        ? l10n.authLoginOrRegister
                                        : (user.email ?? l10n.text_676),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 設定按鈕
                    Container(
                      decoration: BoxDecoration(
                        color: colors.mutedBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.settings_rounded,
                          color: colors.info,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 功能按鈕列
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFeatureButton(
                      context,
                      Icons.history_rounded,
                      AppLocalizations.of(context)!.text_677,
                      'history',
                      colors.info,
                    ),
                    _buildFeatureButton(
                      context,
                      Icons.location_city_rounded,
                      AppLocalizations.of(context)!.text_54,
                      'city',
                      colors.success,
                    ),
                    _buildFeatureButton(
                      context,
                      Icons.airline_stops_rounded,
                      AppLocalizations.of(context)!.text_678,
                      'mile',
                      colors.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ==================== 功能卡片區域 ====================
          Column(
            children: [
              _buildActionCard(context,
                icon: Icons.bug_report_rounded,
                title: AppLocalizations.of(context)!.text_679,
                subtitle: AppLocalizations.of(context)!.text_680,
                color: colors.info,
                onTap: () async {
                  final packageInfo = await PackageInfo.fromPlatform();
                  QuickAlert.show(
                    context: context,
                    type: QuickAlertType.info,
                    text:
                    "版本號: ${packageInfo.version}\n建構號: ${packageInfo.buildNumber}",
                    confirmBtnText: "複製 token",
                    onConfirmBtnTap: () {
                      Clipboard.setData(
                        ClipboardData(text: FCMtoken ?? "無效的 token"),
                      ).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.text_681,
                            ),
                            backgroundColor: colors.info,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      });
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildActionCard(context,
                icon: Icons.feedback_rounded,
                title: AppLocalizations.of(context)!.text_682,
                subtitle: AppLocalizations.of(context)!.text_683,
                color: colors.success,
                onTap: () async {
                  const url = 'https://forms.gle/CfjfDBkFe1vxeAH17';
                  final Uri uri = Uri.parse(url);
                  await launchUrl(uri);
                },
              ),
              // QA B24：「觸發通知」是推播測試功能，只在 Debug / 內部 QA 版顯示。
              if (AppDiagnostics.enabled) ...[
                const SizedBox(height: 12),
                _buildActionCard(
                  context,
                  icon: Icons.notifications_active_rounded,
                  title: AppLocalizations.of(context)!.text_684,
                  subtitle: AppLocalizations.of(context)!.text_685,
                  color: colors.warning,
                  onTap: testTask,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton(
      BuildContext context,
      IconData icon,
      String text,
      String id,
      Color color,
      ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (id == 'city') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TaiwanCitiesPage()),
            );
          } else if (id == 'mile') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MileagePage()),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 圖標
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              // 文字資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // 導航箭頭
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.mutedBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}