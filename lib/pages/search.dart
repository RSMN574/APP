
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../firebase/placeAPI.dart';
import '../Const/regularClass.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _routeController = TextEditingController();
  List<dynamic> _placePredictions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0, // 去掉 AppBar 的阴影
        backgroundColor: Colors.blue, // 设置背景颜色
        title: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 10) {
              // 向下拖动时关闭页面
              Navigator.of(context).pop();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, // 使用白色背景
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 5.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _routeController,
              decoration: InputDecoration(
                hintText: '搜尋',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.blue), // 搜索图标
                  onPressed: _loadPredictions, // 按钮点击事件
                ),
              ),
              onChanged: (value) {
                // 在输入内容时清空建议列表
                setState(() {
                  _placePredictions.clear();
                });
              },
              onSubmitted: (value) {
                _loadPredictions(); // 按下回车键时加载建议
              },
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 增加外边距
        child: Column(
          children: [
            const SizedBox(height: 16.0), // 搜索框和建议列表之间的间距
            // 显示建议列表
            if (_placePredictions.isNotEmpty)
              Expanded(
                child: Material(
                  elevation: 0,
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _placePredictions.length,
                      itemBuilder: (context, index) {
                        final mainText = _placePredictions[index]['structured_formatting']['main_text'];
                        final secondaryText = _placePredictions[index]['structured_formatting']['secondary_text'];

                        return ListTile(
                          leading: const Icon(Icons.location_on, color: Colors.blue),
                          title: Text(mainText, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(secondaryText, style: const TextStyle(color: Colors.grey)),
                          onTap: () async {
                            // 获取当前位置
                            final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                            String origin = '${locationProvider.latitude},${locationProvider.longitude}';
                            Navigator.pushNamed(context, 'home' ,arguments:_placePredictions[index]);
                            // 弹出对话框

                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }



  void _loadPredictions() async {
    PlacesService placesService = PlacesService();
    try {
      List<dynamic> predictions = await placesService.getPlaceAutocomplete(_routeController.text,context);
      setState(() {
        _placePredictions = predictions;
      });
    } catch (e) {
      print('Error: $e');
    }
  }
}
