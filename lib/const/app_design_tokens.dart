import 'package:flutter/material.dart';

/// 全域尺寸與間距 Token
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  /// 頁面左右邊距 (預設 16px)
  static const double pageMargin = 16.0;

  /// 卡片內距 (預設 16px)
  static const double cardPadding = 16.0;

  /// 區塊間距 (預設 16/24px)
  static const double sectionGap = 24.0;
  static const double blockGap = 16.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double full = 999.0;

  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius roundedFull =
      BorderRadius.all(Radius.circular(full));
}

class AppSizes {
  /// 主要圖示 24px
  static const double iconLg = 24.0;

  /// 輔助圖示 18–20px
  static const double iconMd = 20.0;
  static const double iconSm = 18.0;

  /// 輸入框高度 ~48–56px
  static const double inputHeight = 48.0;

  /// 一般按鈕高度 ~48px
  static const double buttonHeight = 48.0;
}

/// 全域文字階層。未指定字型，讓各平台使用可呈現繁體中文的系統字型回退。
class AppTypography {
  static const double displayLarge = 32.0;
  static const double headlineLarge = 24.0;
  static const double titleLarge = 20.0;
  static const double titleMedium = 16.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double labelLarge = 14.0;

  static const double headingHeight = 1.25;
  static const double bodyHeight = 1.5;
  static const double labelHeight = 1.2;
}
