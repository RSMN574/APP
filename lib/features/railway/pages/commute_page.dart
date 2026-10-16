import 'dart:convert';

import 'package:com.rsmn574.app/features/railway/pages/hsr_schedule_page.dart';
import 'package:com.rsmn574.app/features/bus/pages/bus_time_page.dart';
import 'package:com.rsmn574.app/features/railway/pages/train_schedule_page.dart';
import 'package:com.rsmn574.app/task/task.dart';
import 'package:com.rsmn574.app/utils/convert.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:com.rsmn574.app/const/regular_const.dart';
import 'package:com.rsmn574.app/features/railway/data/get_hsr.dart';
import 'package:com.rsmn574.app/features/railway/data/get_train.dart';
import 'package:com.rsmn574.app/database/get_data.dart';
import 'package:com.rsmn574.app/database/sql/schedule.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:com.rsmn574.app/features/bus/model/bus_route_model.dart';

// 定義品牌色
const Color hsrOrange = Color(0xFFF15A24);
const Color traBlue = Color(0xFF003D74);
const Color busBlue = Color(0xFF2196F3);

class Commute extends StatefulWidget {
  @override
  _CommuteState createState() => _CommuteState();
}

class _CommuteState extends State<Commute> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> scheduleData = [];

  @override
  void initState() {
    super.initState();

    fetchScheduleData(); // 初始化时获取数据
  }

  Future<void> scheduleTodayReminders() async {
    // 1. 撈出所有排程

    final data = scheduleData;
    // data 型態: List<Map<String, dynamic>>

    // 2. 取得今天的年月日
    final now = DateTime.now();
    bool isToday(DateTime t) =>
        t.year == now.year && t.month == now.month && t.day == now.day;

    // 3. 過濾出 time 在今天的那幾筆
    final todayItems = data.where((item) {
      final t = item['time'];
      if (t == null) return false;
      // 如果拿到的是 String：
      final dt = t is String
          ? DateTime.parse(t)
          : t is DateTime
              ? t
              : null;
      return dt != null && isToday(dt);
    }).toList();

    // 4. 逐筆設定提醒

    for (final item in todayItems) {
      final type = item['type'] as String;
      if (type == 'train') {
        final routeName = item['Route'].toString();
        final routeID = item['routeID']?.toString() ?? '';
        final city = item['city']?.toString() ?? '';
        final UserStartingStopName = item['UserStartingStopName'] ?? '';
        final UserDestinationStopName = item['UserDestinationStopName'] ?? '';
        // 假設你有把 StopID 存到 other 裡
        final other = item['other'];

        // 呼叫 startReminder
        await startReminder(
          transportType: type,
          routeName: routeName,
          routeID: routeID,
          city: city,
          UserStartingStopName: UserStartingStopName,
          UserDestinationStopName: UserDestinationStopName,
        );
      } else if (type == 'bus') {
        final routeName = item['Route'].toString();
        final routeID = item['routeID']?.toString() ?? '';
        final city = item['city']?.toString() ?? '';
        // 假設你有把 StopID 存到 other 裡
        final other = item['other'];
        final stopID =
            other?['StopID']?.toString() ?? item['StopID']?.toString() ?? '';
        final UserStartingStopName = item['UserStartingStopName'] ?? '';
        final UserDestinationStopName = item['UserDestinationStopName'] ?? '';
        if (stopID.isEmpty) {
          print("第 ${item['id']} 筆缺少 stopID，跳過");
          continue;
        }

        // 呼叫 startReminder
        await startReminder(
          transportType: type,
          routeName: routeName,
          routeID: routeID,
          city: city,
          stopID: stopID,
          UserStartingStopName: UserStartingStopName,
          UserDestinationStopName: UserDestinationStopName,
        );
      }
    }
  }

  Future<void> fetchScheduleData() async {
    await ScheduleService.instance.deleteExpiredSchedules();
    final data = await ScheduleService.instance.getSchedules();

    setState(() {
      scheduleData = data;
    });

    scheduleTodayReminders();
  }

  // 下拉刷新方法
  Future<void> _onRefresh() async {
    await fetchScheduleData(); // 重新获取数据
  }

  Widget _buildCommutePage(String category) {
    final filteredData = scheduleData.where((item) {
      return (item["category"] ?? '').toString().toLowerCase() ==
          category.toLowerCase();
    }).toList();

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: filteredData.isEmpty
          ? _buildEmptyState() // 顯示美化的提示 UI
          : ListView.builder(
              itemCount: filteredData.length,
              itemBuilder: (context, index) {
                final item = filteredData[index];

                return _buildScheduleCard(item);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note,
                size: 80, color: Colors.grey[400]), // 行程 Icon
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.text_37,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.text_38,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: 這裡加入導向新增行程的邏輯
              },
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.text_39),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dialogBuilder(BuildContext context, Map<String, dynamic> data) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 300),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            backgroundColor: Colors.white,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutQuint,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF5F9FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: Text(
                      AppLocalizations.of(context)!.text_40,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: busBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutQuad,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDialogOption(
                            context,
                            Icons.info_outline_rounded,
                            AppLocalizations.of(context)!.text_41,
                            "info",
                            data),
                        const Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 16,
                            endIndent: 16),
                        _buildDialogOption(context, Icons.edit_outlined,
                            AppLocalizations.of(context)!.text_42, "edit"),
                        const Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 16,
                            endIndent: 16),
                        _buildDialogOption(
                            context,
                            Icons.delete_outline_rounded,
                            AppLocalizations.of(context)!.text_43,
                            "remove",
                            data),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: busBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.text_44,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogOption(
      BuildContext context, IconData icon, String title, String id,
      [Map<String, dynamic>? other]) {
    return InkWell(
      onTap: () async {
        // 处理对话框选项点击事件
        if (id == "remove") {
          final schedule = ScheduleModel(
            type: other?['type'],
            id: other?['id'],
            route: other?['Route'],
          );

// 调用 updateSchedule 来更新现有的排程
          print(other?['id']);
          print(other?['type']);
          print(other?['Route']);
          final result =
              await ScheduleService.instance.removeSchedule(model: schedule);

          if (result == -1) {
            // 如果已经存在相同的记录，提示用户
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.text_45)));
          } else if (result == 100) {
            // 成功添加行程，提示用户
            fetchScheduleData();
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.text_46)));
          } else {
            // 添加行程失败，提示用户
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.text_47)));
          }

          // 1. 呼叫 removeReminder 刪除該筆提醒
          await removeReminder(other!['Route'].toString());
          Navigator.pop(context); // 关闭弹窗
        } else if (id == "info") {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  backgroundColor: Colors.white,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutQuint,
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Color(0xFFF5F9FF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0.8, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.elasticOut,
                          builder: (context, double value, child) {
                            return Transform.scale(
                              scale: value,
                              child: child,
                            );
                          },
                          child: Text(
                            AppLocalizations.of(context)!.text_48,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: busBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutQuad,
                          builder: (context, double value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildInfoRow(
                                  AppLocalizations.of(context)!.text_49,
                                  other?['StartingStopName'] ?? ''),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                  AppLocalizations.of(context)!.text_50,
                                  other?['FinalStopName'] ?? ''),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                  AppLocalizations.of(context)!.text_51,
                                  other?['UserStartingStopName'] ?? ''),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                  AppLocalizations.of(context)!.text_52,
                                  other?['UserDestinationStopName'] ?? ''),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          builder: (context, double value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: busBlue,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.text_44,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: busBlue),
            const SizedBox(width: 10),
            Flexible(child: Text(title, style: const TextStyle(fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBusCard(Map<String, dynamic> data) {
    // 定義顏色
    const Color primaryBusColor = Color(0xFF2196F3);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onLongPress: () => _dialogBuilder(context, data),
            onTap: () async {
              if (data['type'] == "bus") {
                BusRoute route = BusRoute.fromJson(await getBusRouteWithId(
                    city: cityNameConverter(data['city']),
                    routeId: data["routeID"].toString()));
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BusTime(
                        routeName: route.routeZh,
                        departureStopName: route.departureStopNameZh,
                        destinationStopName: route.destinationStopNameZh,
                        operators: route.operatorName,
                        routeMapImageUrl: route.routeMapUrl,
                        city: route.routeCity ?? 'InterCity',
                        routeID: route.routeId,
                        hasSubRoutes: route.hasSubRoute,
                        data: route),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 頂部：路線編號與類型標籤
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.directions_bus_rounded,
                              color: primaryBusColor, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            data['Route'] ??
                                AppLocalizations.of(context)!.text_53,
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryBusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data['city'] ?? AppLocalizations.of(context)!.text_54,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryBusColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 中部：起終點流向圖
                  Row(
                    children: [
                      _buildStationPoint(
                          label: AppLocalizations.of(context)!.text_55,
                          name: data['UserStartingStopName'] ??
                              AppLocalizations.of(context)!.text_56,
                          align: CrossAxisAlignment.start),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            children: [
                              Icon(Icons.arrow_forward,
                                  color: Colors.grey.shade300, size: 20),
                              const SizedBox(height: 4),
                              // 虛線裝飾 (可選)
                              Container(height: 1, color: Colors.grey.shade100),
                            ],
                          ),
                        ),
                      ),
                      _buildStationPoint(
                          label: AppLocalizations.of(context)!.text_57,
                          name: data['UserDestinationStopName'] ??
                              AppLocalizations.of(context)!.text_56,
                          align: CrossAxisAlignment.end),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF5F5F5)),
                  const SizedBox(height: 12),

                  // 底部：類型提示與小細節
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.text_58,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'ID: ${data['routeID'] ?? '--'}',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            fontFamily: 'RobotoMono'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// 輔助組件：站點資訊單元
  Widget _buildStationPoint(
      {required String label,
      required String name,
      required CrossAxisAlignment align}) {
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _editSeatNumber(BuildContext context, TextEditingController controller,
      Map<String, dynamic> data, String type) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF5F9FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.text_59,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: busBlue,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  maxLength: 10,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.text_60,
                    counterText: "",
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.text_36,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          String newSeatNumber = controller.text.trim();
                          if (newSeatNumber.isNotEmpty) {
                            // 更新座位號碼
                            final schedule = ScheduleModel(
                                id: data["id"], // 确保 id 是有效的
                                type: type,
                                route: data['Route'], // 提供 route 参数
                                startingStopName: data[
                                    'UserStartingStopName'], // 提供 startingStopName 参数
                                finalStopName: data[
                                    'UserDestinationStopName'], // 提供 finalStopName 参数
                                seatNumber: newSeatNumber // 更新 seatNumber
                                );

// 调用 updateSchedule 来更新现有的排程
                            final output = await ScheduleService.instance
                                .updateSchedule(schedule);

                            // 根据 updateSchedule 方法返回的结果进行处理
                            if (output == -1) {
                              // 如果已经存在相同的记录，提示用户
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          AppLocalizations.of(context)!
                                              .text_61)));
                            } else if (output == 100) {
                              // 成功添加行程，提示用户
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          AppLocalizations.of(context)!
                                              .text_62)));
                            } else {
                              // 添加行程失败，提示用户
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          AppLocalizations.of(context)!
                                              .text_61)));
                            }
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: busBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.text_35,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          // 增加點擊水波紋效果
          color: Colors.transparent,
          child: InkWell(
            onLongPress: () => _dialogBuilder(context, data),
            onTap: () async {
              // ... 原有的跳轉邏輯保持不變 ...
              var trainData = await fetchHSR(
                int.parse(data['Route'].replaceAll(RegExp(r'[^0-9]'), ''))
                    .toString()
                    .padLeft(4, '0'),
                (DateTime.parse((data["time"]))),
              );
              if (data['type'] == "train") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrainSchedulePage(
                        type: 'trainNo',
                        time: (DateTime.parse((data["time"]))),
                        trainNo: int.parse(
                            data['Route'].replaceAll(RegExp(r'[^0-9]'), ''))),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HSRSchedulePage(
                      trainData: trainData,
                      type: 'trainNo',
                      time: (DateTime.parse((data["time"]))),
                    ),
                  ),
                );
              }
            },
            child: _buildInnerContent(data),
          ),
        ),
      ),
    );
  }

  Widget _buildInnerContent(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'train':
        return _buildTrainCard(data);
      case 'HSR':
        return _buildHSRCard(data);
      default:
        return _buildBusCard(data);
    }
  }

  Widget _buildTrainStationInfo(String? name, String type) {
    // 根據是起點還是終點，決定對齊方向
    bool isStart = type == "START";

    return Column(
      crossAxisAlignment:
          isStart ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        // 英文標籤，增加專業感
        Text(
          isStart ? 'DEPARTURE' : 'ARRIVAL',
          style: TextStyle(
            color: Colors.orangeAccent.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        // 中文標籤
        Text(
          isStart
              ? AppLocalizations.of(context)!.text_63
              : AppLocalizations.of(context)!.text_64,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        // 站名（大字體）
        Text(
          name ?? '--',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrainCard(Map<String, dynamic> data) {
    String seatNumber = data['seatNumber'] ?? '';
    TextEditingController seatController =
        TextEditingController(text: seatNumber);
    String trainType =
        convertTrainType(json.decode(data["other"])["trainType"]);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF003D74), Color(0xFF005BA1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(trainType,
                    style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold)),
                Text(data['Route'] ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildTrainStationInfo(data['UserStartingStopName'], "START"),
                const Expanded(child: DashLineConnector()), // 自定義虛線組件
                _buildTrainStationInfo(data['UserDestinationStopName'], "END"),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                    DateFormat('MM/dd HH:mm')
                        .format(DateTime.parse(data["time"])),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                if (trainType != AppLocalizations.of(context)!.text_65 &&
                    trainType != AppLocalizations.of(context)!.text_66)
                  _buildSeatBadge(
                      seatNumber,
                      () => _editSeatNumber(
                          context, seatController, data, "train"),
                      isDark: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

// 高鐵專用卡片組件
  Widget _buildHSRCard(Map<String, dynamic> data) {
    String seatNumber = data['seatNumber'] ?? '';
    TextEditingController seatController =
        TextEditingController(text: seatNumber);

    return Column(
      children: [
        // 頂部條
        Container(
          color: hsrOrange,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.speed, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text('台灣高鐵 THSR',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const Spacer(),
              Text(data['Route'] ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'RobotoMono',
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildRouteStation(AppLocalizations.of(context)!.text_67,
                      data['UserStartingStopName'], CrossAxisAlignment.start),
                  const Icon(Icons.trending_flat, color: Colors.grey),
                  _buildRouteStation(AppLocalizations.of(context)!.text_68,
                      data['UserDestinationStopName'], CrossAxisAlignment.end),
                ],
              ),
              const Divider(height: 32),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                      DateFormat('yyyy/MM/dd')
                          .format(DateTime.parse(data["time"])),
                      style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                  const Spacer(),
                  _buildSeatBadge(
                      seatNumber,
                      () => _editSeatNumber(
                          context, seatController, data, "HSR")),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

// 1. 座位按鈕樣式
  Widget _buildSeatBadge(String seat, VoidCallback onTap,
      {bool isDark = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark ? Colors.white30 : Colors.blue.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_seat,
                size: 14, color: isDark ? Colors.orangeAccent : Colors.blue),
            const SizedBox(width: 4),
            Flexible(child: Text(
              seat.isEmpty
                  ? AppLocalizations.of(context)!.text_69
                  : '座位: $seat',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
          ],
        ),
      ),
    );
  }

// 2. 站點資訊樣式
  Widget _buildRouteStation(
      String label, String? name, CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        Text(name ?? '--',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

// 高鐵站點組件
  Widget _buildHSRStation(String type, String stationName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stationName,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        )
      ],
    );
  }

// 站點資訊組件
  Widget _buildStationInfo(String type, String stationName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type,
          style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w300),
        ),
        Text(
          stationName,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        )
      ],
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // scheduleTodayReminders();
    final List<Widget> pages = [
      _buildCommutePage("commute"),
      _buildCommutePage("trip"),
    ];

    return Column(
      children: [
        // 模擬 AppBar
        CustomBottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
        // PageView
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: pages,
          ),
        ),
      ],
    );
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTabItem(
              index: 0,
              icon: Icons.directions_bus,
              label: AppLocalizations.of(context)!.text_70,
            ),
            _buildTabItem(
              index: 1,
              icon: Icons.airplanemode_active,
              label: AppLocalizations.of(context)!.text_71,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[800] : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 3. 虛線連接器 (用於台鐵)
class DashLineConnector extends StatelessWidget {
  const DashLineConnector({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      height: 1,
      child: LayoutBuilder(builder: (context, constraints) {
        return Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
              (constraints.constrainWidth() / 5).floor(),
              (index) => const SizedBox(
                  width: 3,
                  height: 1,
                  child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.white38)))),
        );
      }),
    );
  }
}
