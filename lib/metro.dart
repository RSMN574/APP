import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

import 'Const/regularClass.dart';

class Metro extends StatefulWidget {
  const Metro({super.key});

  @override
  State<Metro> createState() => _MetroState();
}

class _MetroState extends State<Metro> {
  final List<String> _list = [
    "臺北市",
    "桃園市",
    '臺中市',
    "高雄市"
  ];

  String _selectedCity = "臺北市"; // 默认选项

  @override
  void initState() {
    super.initState();
    // 在初始化状态中获取当前城市
    String currentCity = Provider.of<CityProvider>(context, listen: false).city;

    // 检查 currentCity 是否在 _list 中
    if (_list.contains(currentCity)) {
      _selectedCity = currentCity; // 正确赋值
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("捷運")),
      body: Column(
        children: [
          CustomDropdown<String>(
            hintText: '選擇城市',
            items: _list,
            initialItem: _selectedCity,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCity = value; // 更新选中的城市
                });
              }
            },
          ),
          const SizedBox(height: 20),
          // 根据选择的城市展示不同内容
          Expanded(
            child: Center(
              child: _buildCityText(_selectedCity), // 根据选择的城市显示不同文本
            ),
          ),
        ],
      ),
    );
  }

  // 根据选中的城市返回不同的 Widget
  Widget _buildCityText(String city) {
    String imageUrl;
    switch (city) {
      case "臺北市":
        imageUrl = "https://github.com/RSMN574/assets/blob/main/TRTC_map.jpg?raw=true";
        break;
      case "桃園市":
        imageUrl = "https://github.com/RSMN574/assets/blob/main/TYMC_map.jpg?raw=true";
        break;
      case "臺中市":
        imageUrl = "https://github.com/RSMN574/assets/blob/main/TMRT_map.jpg?raw=true";
        break;
      case "高雄市":
        imageUrl = "https://github.com/RSMN574/assets/blob/main/KMRT_map.jpg?raw=true";
        break;
      default:
        return const Text("未知的城市");
    }

    return FutureBuilder<Image>(
      future: _loadImage(imageUrl),
      builder: (BuildContext context, AsyncSnapshot<Image> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: LoadingAnimationWidget.stretchedDots(
              color: Colors.black,
              size: 40,
            ),
          ); // 加载时显示进度指示器
        } else if (snapshot.hasError) {
          return const Text("加载失败"); // 显示加载错误
        } else {
          return InteractiveViewer(
            child: snapshot.data!,
          ); // 显示加载的图像
        }
      },
    );
  }

  // 加载图像的 Future
  Future<Image> _loadImage(String url) async {
    final image = Image.network(url);
    await precacheImage(image.image, context); // 预加载图像
    return image;
  }
}
