import 'package:flutter/material.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:url_launcher/url_launcher.dart';

class ImgSwiper extends StatefulWidget {
  const ImgSwiper({super.key});

  @override
  State<ImgSwiper> createState() => _ImgSwiperState();
}

class _ImgSwiperState extends State<ImgSwiper> {

  void _launchURL() async {
    final url = Uri.parse('https://www.tpass.tw');  // 创建 Uri 对象

    // 强制使用 Web 浏览器打开链接
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication, // 强制使用外部应用（浏览器）
      );
    } else {
      print('无法打开 $url');  // 调试信息，确保获取到具体错误信息
    }

  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = [
      'https://raw.githubusercontent.com/RSMN574/assets/refs/heads/main/tpass.jpg',
      'https://placehold.co/600x300/000000/FFFFFF/png?text=Image+2',
      'https://placehold.co/600x300/000000/FFFFFF/png?text=Image+3',
    ];

    return SizedBox(
      height: 200, // 定义高度
      child: Swiper(
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: _launchURL,  // 点击图片跳转
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15), // 圆角边框
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: Offset(0, 4),
                    blurRadius: 10,
                  ),
                ], // 阴影效果
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15), // 保持圆角效果
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover, // 适应容器大小
                ),
              ),
            ),
          );
        },
        itemCount: imageUrls.length,
        viewportFraction: 0.8,
        scale: 0.9,// 使用实际图片数量
        autoplay: true, // 自动播放
        pagination: const SwiperPagination(
          alignment: Alignment.bottomCenter,
          margin: EdgeInsets.all(10),
          builder: DotSwiperPaginationBuilder(
            activeColor: Colors.blueAccent, // 点的颜色
            color: Colors.grey, // 非选中点的颜色
          ),
        ),
        // control: const SwiperControl(),
      ),
    );
  }
}
