
import 'package:flutter/material.dart';
final   tokenUri=Uri.parse('http://hidden.rsmn574.com:3920/token') ;
final   tokens=Uri.parse('http://hidden.rsmn574.com:3920/tokens') ;
const Color primary=Color.fromRGBO(0,125,254, 1);
const Color secondary=Color.fromRGBO(38,38,38, 1);
const Color blue=Color.fromRGBO(36,137,243, 1);
 const Color busBlue=Color.fromRGBO(2,101,143, 1);
final Color startColor = Color.fromARGB(255, 13, 193, 255); // (13,193,255)
final Color endColor = Color.fromARGB(255, 27, 141, 255);   // (27,141,255)
final Color bgColor =Color.fromRGBO(245,245,245,1);
final Color bgColorWhite =Colors.white;
class AppThemes {
 /// 自動判斷並回傳當前主題的 Primary 顏色
 static Color getPrimary(BuildContext context) {
  // 透過 Theme.of(context) 取得目前生效的 ColorScheme
  return Theme.of(context).colorScheme.primary;
 }

 static Color getTextColor(BuildContext context) {
  // 透過 Theme.of(context) 取得目前生效的 ColorScheme
  return Theme.of(context).colorScheme.primary;
 }
 /// 獲取 Dropdown 彈出層的背景色
 static Color getDropdownMenuColor(BuildContext context) {
  bool isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? const Color(0xFF1C1C1E) : Colors.white;
 }

 /// 獲取選中項目的高亮色
 static Color getHighlightColor(BuildContext context) {
  return Theme.of(context).colorScheme.primary.withOpacity(0.1);
 }
 /// 自動判斷並回傳當前主題的 Surface (背景) 顏色
 static Color getSurface(BuildContext context) {
  return Theme.of(context).colorScheme.surface;
 }
 static Color getOnSurface(BuildContext context) {
  return Theme.of(context).colorScheme.onSurface;
 }
 static Color? getCardColor(BuildContext context) {
  return Theme.of(context).cardTheme.color;
 }
 static  NavigationBarThemeData  getNavigationBarTheme(BuildContext context) {
  return Theme.of(context).navigationBarTheme;
 }

 /// 自動判斷並回傳當前主題的文字顏色 (OnSurface)
 static InputDecorationThemeData inputTheme(BuildContext context) {
  return Theme.of(context).inputDecorationTheme;
 }
 static Color getInputFillColor(BuildContext context) {
  return Theme.of(context).inputDecorationTheme.fillColor ?? Colors.transparent;
 }

 static AppBarThemeData getAppBarTheme(BuildContext context) {
  return Theme.of(context).appBarTheme;
 }
 // --- 淺色模式配置 ---
 static final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
   seedColor: Colors.blue,
   brightness: Brightness.light,
   primary: const Color(0xFF1A73E8),
   onPrimary: Colors.white,
   surface: Colors.white,
   onSurface: Colors.black,
   surfaceContainerHighest: Colors.grey[100], // 用於輸入框背景
  ),
  scaffoldBackgroundColor: Colors.white,

  // AppBar 樣式
  appBarTheme: const AppBarTheme(
   backgroundColor: Colors.white,
   foregroundColor: Colors.black, // 控制文字與 Icon 顏色
   elevation: 0,
   centerTitle: true,
   titleTextStyle: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black,
   ),
   iconTheme: IconThemeData(color: Colors.black),

  ),

  // 按鈕樣式
  elevatedButtonTheme: ElevatedButtonThemeData(
   style: ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: Colors.blue,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
   ),
  ),

  // 輸入框樣式
  inputDecorationTheme: InputDecorationTheme(
   filled: true,
   fillColor: Colors.white,
   border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
   ),
   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),

  // 文本樣式
  textTheme: const TextTheme(
   bodyLarge: TextStyle(fontSize: 18, color: Colors.black),
   bodyMedium: TextStyle(fontSize: 16, color: Colors.black54),
   titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
  ),

  navigationBarTheme: NavigationBarThemeData(
   height: 64,
 backgroundColor: Colors.white,
  indicatorColor: Colors.transparent, // 選中時的膠囊背景色 (淡藍)
  iconTheme: WidgetStateProperty.resolveWith((states) {
   if (states.contains(WidgetState.selected)) {
    return const IconThemeData(color: Color(0xFF1A73E8)); // 選中時圖示顏色
   }
   return const IconThemeData(color: Colors.black54); // 未選中圖示顏色
  }),
   labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
        (Set<WidgetState> states) {
     final isSelected = states.contains(WidgetState.selected);
     return TextStyle(
      fontSize: isSelected ? 12 : 11,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      color: isSelected ? Colors.blueAccent : Colors.grey[600],
      letterSpacing: 0.2,
     );
    },
   ),),
// 在 lightTheme 中
     dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
       backgroundColor: WidgetStateProperty.all(Colors.white),
       elevation: WidgetStateProperty.all(8),
      ),
     ),

 );

 // --- 深色模式配置 ---
 static final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
   seedColor: Colors.blue,
   brightness: Brightness.dark,
   primary: Colors.blue,
   onPrimary: Colors.white,
   surface: const Color(0xFF121212), // 經典深色背景
   onSurface: Colors.white,          // 深色模式文字改為白色
   surfaceContainerHighest: const Color(0xFF2C2C2C), // 深色輸入框背景

  ),
  scaffoldBackgroundColor: const Color(0xFF121212),

  // AppBar 樣式
  appBarTheme: const AppBarTheme(
   backgroundColor: Color(0xFF1C1C1E),
   foregroundColor: Colors.white,
   elevation: 0,
   centerTitle: true,
   titleTextStyle: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
   ),
   iconTheme: IconThemeData(color: Colors.white),

  ),

  // 按鈕樣式 (深色模式按鈕通常維持主色)
  elevatedButtonTheme: ElevatedButtonThemeData(
   style: ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: Colors.blue,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0, // 深色模式通常減少陰影感
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
   ),
  ),

  // 輸入框樣式
  inputDecorationTheme: InputDecorationTheme(
   filled: true,
   fillColor: const Color(0xFF1C1C1E),
   border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
   ),
   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),

  // 文本樣式
  textTheme: const TextTheme(
   bodyLarge: TextStyle(fontSize: 18, color: Colors.white),
   bodyMedium: TextStyle(fontSize: 16, color: Colors.white70),
   titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
  ),
// Card 樣式
     cardTheme: CardThemeData(
      color: Colors.white, // 套用你的 0xFF1C1C1E
      elevation: 0,                   // iOS 風格通常不使用陰影，靠顏色區分層次
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
       borderRadius: BorderRadius.circular(12), // iOS 偏好較大的圓角
      ),
     ),

     // 列表 ListTile 樣式 (公車 App 常用)
     listTileTheme: const ListTileThemeData(
      tileColor: Colors.transparent,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: TextStyle(fontSize: 17, color: Color(0xFFE5E5E7)),
      subtitleTextStyle: TextStyle(fontSize: 14, color: Colors.grey),
     ),
      navigationBarTheme: NavigationBarThemeData(
       height: 64,
 backgroundColor: const Color(0xFF1E1E1E), // 深灰背景
          indicatorColor: Colors.transparent,
 iconTheme: WidgetStateProperty.resolveWith((states) {
 if (states.contains(WidgetState.selected)) {
 return const IconThemeData(color: Colors.blue); // 選中時圖示
 }
 return const IconThemeData(color: Colors.white70); // 未選中圖示
 }),

       labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
            (Set<WidgetState> states) {
         final isSelected = states.contains(WidgetState.selected);
         return TextStyle(
          fontSize: isSelected ? 12 : 11,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.blueAccent : Colors.grey[600],
          letterSpacing: 0.2,
         );
        },
       ),
 ),
     // 在 darkTheme 中
     dropdownMenuTheme: DropdownMenuThemeData(
 menuStyle: MenuStyle(
 // 使用你選定的 iOS 風格深灰色
 backgroundColor: WidgetStateProperty.all(const Color(0xFF1C1C1E)),
 elevation: WidgetStateProperty.all(0), // 深色模式通常靠顏色區分，不靠陰影
 ),

 )
 );
}

//NavigationBarThemeData(
//               height: 64,
//               indicatorColor: Colors.white.withOpacity(0.5),
//               labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
//                     (Set<WidgetState> states) {
//                   final isSelected = states.contains(WidgetState.selected);
//                   return TextStyle(
//                     fontSize: isSelected ? 12 : 11,
//                     fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
//                     color: isSelected ? Colors.blueAccent : Colors.grey[600],
//                     letterSpacing: 0.2,
//                   );
//                 },
//               ),
//             ),