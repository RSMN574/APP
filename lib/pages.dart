import 'package:com.rsmn574.app/task/task.dart';
import 'package:com.rsmn574.app/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase/FCM.dart';
import 'pages/city.dart';
import 'pages/other/settings.dart';

class InfoPages extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 用戶資料卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
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
                    // 用戶頭像
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A73E8), Color(0xFF1A73E8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 用戶資訊
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nick',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A73E8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '測試BETA人員',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 設定按鈕
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF3FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.settings_rounded,
                          color: Color(0xFF1A73E8),
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SettingsPage()),
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
                      '歷史行程',
                      'history',
                      const Color(0xFF1A73E8),
                    ),
                    _buildFeatureButton(
                      context,
                      Icons.location_city_rounded,
                      '城市',
                      'city',
                      const Color(0xFF34C759),
                    ),
                    _buildFeatureButton(
                      context,
                      Icons.airline_stops_rounded,
                      '里程',
                      'mile',
                      const Color(0xFFFF9500),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 功能卡片區域
          Column(
            children: [
              _buildActionCard(
                icon: Icons.bug_report_rounded,
                title: '版本資訊',
                subtitle: '查看應用版本與詳細資訊',
                color: const Color(0xFF1A73E8),
                onTap: () async {
                  final packageInfo = await PackageInfo.fromPlatform();
                  QuickAlert.show(
                    context: context,
                    type: QuickAlertType.info,
                    text: "版本號: ${packageInfo.version}\n建構號: ${packageInfo.buildNumber}",
                    confirmBtnText: "複製 token",
                    onConfirmBtnTap: () {
                      Clipboard.setData(ClipboardData(text: FCMtoken ?? "無效的 token"))
                          .then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Token 複製到剪貼簿'),
                            backgroundColor: const Color(0xFF1A73E8),
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
              _buildActionCard(
                icon: Icons.feedback_rounded,
                title: '回報BUG 和建議',
                subtitle: '協助我們改進應用程式',
                color: const Color(0xFF34C759),
                onTap: () async {
                  const url = 'https://forms.gle/CfjfDBkFe1vxeAH17';
                  final Uri uri = Uri.parse(url);
                  await launchUrl(uri);
                },
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.notifications_active_rounded,
                title: '觸發通知',
                subtitle: '測試推播通知功能',
                color: const Color(0xFFFF9500),
                onTap: testTask,
              ),

            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton(BuildContext context, IconData icon, String text, String id, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (id == 'city') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TaiwanCitiesPage()),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
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

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
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
                    colors: [color, color.withOpacity(0.8)],
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
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
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}