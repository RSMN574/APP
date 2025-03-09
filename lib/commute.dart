import 'dart:convert';

import 'package:com.rsmn574.app/pages/HSR/HSRSchedulePage.dart';
import 'package:com.rsmn574.app/pages/bus_time.dart';
import 'package:com.rsmn574.app/pages/train/TrainSchedule.dart';
import 'package:com.rsmn574.app/utils/convert.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'Const/regularConst.dart';
import 'database/HSR/getHSR.dart';
import 'database/Train/getTrain.dart';
import 'database/getData.dart';
import 'database/SQL/schedule.dart';

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

  Future<void> fetchScheduleData() async {
    final db = schedule();
    final data = await db.getSchedule(
      "schedule",
    );
    setState(() {
      scheduleData = data;
    });
  }

  // 下拉刷新方法
  Future<void> _onRefresh() async {
    await fetchScheduleData(); // 重新获取数据
  }

  Widget _buildCommutePage(String category) {
    final filteredData = scheduleData.where((item) {
      return item["category"] == category;
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
            const Text(
              "還沒有規劃的行程",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              "點擊下方按鈕來新增你的第一個行程吧！",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: 這裡加入導向新增行程的邏輯
              },
              icon: const Icon(Icons.add),
              label: const Text("新增行程"),
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
                    child: const Text(
                      "行程選項",
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
                        _buildDialogOption(context, Icons.info_outline_rounded,
                            "查看行程資訊", "info", data),
                        const Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 16,
                            endIndent: 16),
                        _buildDialogOption(
                            context, Icons.edit_outlined, "編輯行程", "edit"),
                        const Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 16,
                            endIndent: 16),
                        _buildDialogOption(
                            context,
                            Icons.delete_outline_rounded,
                            "移除行程",
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
                        child: const Text(
                          '關閉',
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
          final db = schedule();
          int result = await db.removeSchedule(
            city: other?['type'] == "train" ? '' : (other?['city'] ?? ''),
            type: other?['type'],
            table: 'schedule',
            UserStartingStopName: other?['UserStartingStopName'],
            UserDestinationStopName: other?['UserDestinationStopName'],
            StartingStopName: other?['StartingStopName'],
            FinalStopName: other?['FinalStopName'],
            route: other?['Route'],
          );

          if (result == -1) {
            // 如果已经存在相同的记录，提示用户
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('行程錯誤！')));
          } else if (result == 100) {
            // 成功添加行程，提示用户
            fetchScheduleData();
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('行程刪除成功！')));
          } else {
            // 添加行程失败，提示用户
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('行程刪除失败。')));
          }
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
                          child: const Text(
                            "路線資訊",
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
                                  '路線起點', other?['StartingStopName'] ?? ''),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                  '路線終點', other?['FinalStopName'] ?? ''),
                              const SizedBox(height: 12),
                              _buildInfoRow('用戶上車站',
                                  other?['UserStartingStopName'] ?? ''),
                              const SizedBox(height: 12),
                              _buildInfoRow('用戶下車站',
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
                              child: const Text(
                                '關閉',
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
            Text(title, style: const TextStyle(fontSize: 18)),
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
    return GestureDetector(
      onLongPress: () => _dialogBuilder(context, data), // 传递上下文和当前数据
      onTap: () async {
        if (data['type'] == "bus") {
          await GetBusInfo(
              routeid: data["routeID"], city: cityNameConverter(data['city']));
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (
              context,
            ) =>
                    BusTime(
                      routeName: data['Route'],
                      departureStopName: data["StartingStopName"],
                      destinationStopName: data["FinalStopName"],
                      operators: "",
                      city: cityNameConverter(data['city']),
                      routeID: data["routeID"],
                    )),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 路線標題
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '路線: ${data['Route']}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // 顯示交通工具類型
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1), // 背景色
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '類型: 公車',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue, // 文字顏色
              ),
            ),
          ),
          const SizedBox(height: 16), // 增加間距

          // 起點與終點區域
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '起點',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['UserStartingStopName'] ?? '未設定',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16), // 間距
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '終點',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['UserDestinationStopName'] ?? '未設定',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // 增加間距

          // 城市部分
          Text(
            '城市: ${data['city']}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic, // 斜體
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> data) {
// json.decode(data["other"]);
    return GestureDetector(
      onLongPress: () => _dialogBuilder(context, data),
      onTap: () async {
        if (data['type'] == "bus") {
          await GetBusInfo(
              routeid: data["routeID"], city: cityNameConverter(data['city']));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BusTime(
                routeName: data['Route'],
                departureStopName: data["StartingStopName"],
                destinationStopName: data["FinalStopName"],
                operators: "",
                city: cityNameConverter(data['city']),
                routeID: data["routeID"],
              ),
            ),
          );
        } else if (data['type'] == "train") {
          var fetchedTrainData = await fetchTrain(
              int.parse(data['Route'].replaceAll(RegExp(r'[^0-9]'), '')),
              (DateTime.parse((data["time"]))));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrainSchedulePage(
                trainData: fetchedTrainData,
                type: 'trainNo',
                time: DateTime.parse(data["time"]),
              ),
            ),
          );
        } else if (data['type'] == "HSR") {
          var trainData = await fetchHSR(
            int.parse(data['Route'].replaceAll(RegExp(r'[^0-9]'), ''))
                .toString()
                .padLeft(4, '0'),
            (DateTime.parse((data["time"]))),
          );
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: data['type'] == 'train' ? Colors.blueGrey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
          // 火車專用邊框樣式
          border: data['type'] == 'train'
              ? Border.all(color: Colors.orangeAccent, width: 2)
              : null,
        ),
        child: data['type'] == 'train'
            ? _buildTrainCard(data) // 火車專用樣式
            : data['type'] == 'HSR'
                ? _buildHSRCard(data)
                : _buildBusCard(data), // 原始公車樣式
      ),
    );
  }

  Widget _buildTrainCard(Map<String, dynamic> data) {
    String seatNumber = data['seatNumber'] ?? ''; // 取得座位號碼
    TextEditingController seatController =
        TextEditingController(text: seatNumber);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 車次類型標籤
        Row(
          children: [
            const Icon(Icons.train, color: Colors.orangeAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              '鐵路班次'.toUpperCase(),
              style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 主要車次資訊
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 左側：車次資訊
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['Route'] ?? '車次資訊',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'RobotoMono'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    convertTrainType(json.decode(data["other"])["trainType"]),
                    style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

            // 右側：站點資訊
            Expanded(
              child: Column(
                children: [
                  _buildStationInfo('出發', data['UserStartingStopName']),
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey[400], height: 1),
                  const SizedBox(height: 8),
                  _buildStationInfo('抵達', data['UserDestinationStopName']),
                ],
              ),
            ),
          ],
        ),

        // 底部資訊（時間 + 座位號）
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              Icon(Icons.access_time_filled_sharp,
                  color: Colors.grey[400], size: 16),
              const SizedBox(width: 4),
              Text(
                '時間：${DateFormat('yyyy-MM-dd').format(DateTime.parse(data["time"]))}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),

              // 座位號顯示（可點擊修改）
              GestureDetector(
                onTap: () {
                  _editSeatNumber(context, seatController, data);
                },
                child: Row(
                  children: [
                    Icon(Icons.event_seat, color: Colors.grey[400], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      seatNumber.isEmpty ? '點擊輸入座位號' : '座位號: $seatNumber',
                      style: TextStyle(
                        color: seatNumber.isEmpty
                            ? Colors.redAccent
                            : Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _editSeatNumber(BuildContext context, TextEditingController controller,
      Map<String, dynamic> data) {
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
                const Text(
                  "輸入座位號",
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
                    hintText: "請輸入座位號",
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
                        child: const Text(
                          '取消',
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
                            final schedule _schedule = schedule();
                            final output = await _schedule.updateSchedule(
                                id: data["id"],
                                type: 'train',
                                other: {"seatNumber": newSeatNumber});
                            // 根据 updateSchedule 方法返回的结果进行处理
                            if (output == -1) {
                              // 如果已经存在相同的记录，提示用户
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('更新失敗。')));
                            } else if (output == 100) {
                              // 成功添加行程，提示用户
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('更新成功！')));
                            } else {
                              // 添加行程失败，提示用户
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('更新失敗。')));
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
                        child: const Text(
                          '確認',
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
              label: '上班通勤',
            ),
            _buildTabItem(
              index: 1,
              icon: Icons.airplanemode_active,
              label: '旅行',
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

// 高鐵專用卡片組件
Widget _buildHSRCard(Map<String, dynamic> data) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 高鐵標題列
      Row(
        children: [
          Icon(Icons.directions_railway_filled,
              color: Colors.grey[800], size: 24),
          const SizedBox(width: 10),
          Text(
            '台灣高鐵'.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // 主要資訊區
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左側：班次資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['Route'] ?? '--',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'RobotoCondensed',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  convertTrainType(json.decode(data["other"])["trainType"]),
                  style: TextStyle(
                    color: Colors.blueGrey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 右側：站點時間
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _buildHSRStation('出發', data['UserStartingStopName']),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  _buildHSRStation('抵達', data['UserDestinationStopName']),
                ],
              ),
            ),
          ),
        ],
      ),

      // 時間與城市資訊
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.pin_drop_outlined,
                    color: Colors.blueGrey[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  '城市：${data['city']}',
                  style: TextStyle(
                    color: Colors.blueGrey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.blueGrey[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  DateFormat('yyyy/MM/dd HH:mm')
                      .format(DateTime.parse(data["time"])),
                  style: TextStyle(
                    color: Colors.blueGrey[800],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      )
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
