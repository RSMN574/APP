import 'package:flutter/material.dart';

/// 全域尺寸與間距 Token
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  /// 首頁卡片群組間距
  static const double xl20 = 20.0;
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

  /// 圖示容器（AppBar 按鈕、列表圖示）與首頁交通入口
  static const double iconContainer = 48.0;
  static const double iconContainerLarge = 56.0;

  static const double appBarHeight = kToolbarHeight;
  static const double navigationBarHeight = 64.0;

  /// 單行 / 雙行列表項目高度
  static const double listItemHeight = 56.0;
  static const double listItemHeightTwoLine = 72.0;

  static const double minTouchTarget = 48.0;
  static const double borderWidth = 1.0;
  static const double borderWidthSelected = 1.5;
}

/// 動畫時間與曲線。使用前需檢查 `MediaQuery.disableAnimations`。
class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Curve standard = Curves.easeOutCubic;

  /// 系統要求減少動畫時回傳 0。
  static Duration of(BuildContext context, Duration duration) =>
      (MediaQuery.maybeOf(context)?.disableAnimations ?? false)
          ? Duration.zero
          : duration;
}

/// 全域文字階層。未指定字型，讓各平台使用可呈現繁體中文的系統字型回退。
class AppTypography {
  static const double displayLarge = 32.0;
  static const double headlineLarge = 24.0;
  static const double titleLarge = 20.0;
  static const double titleMedium = 16.0;
  static const double titleSmall = 14.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;

  /// 到站時間（等寬數字）
  static const double arrivalTime = 17.0;

  static const double headingHeight = 1.25;
  static const double titleHeight = 1.3;
  static const double bodyHeight = 1.5;
  static const double captionHeight = 1.35;
  static const double labelHeight = 1.2;

  /// 依設計系統產生 TextTheme；顏色由 [onSurface] / [onSurfaceVariant] 決定。
  static TextTheme textTheme({
    required Color onSurface,
    required Color onSurfaceVariant,
  }) {
    TextStyle s(double size, FontWeight w, double h, Color c) =>
        TextStyle(fontSize: size, fontWeight: w, height: h, color: c);
    return TextTheme(
      displaySmall: s(displayLarge, FontWeight.w800, headingHeight, onSurface),
      headlineSmall:
          s(headlineLarge, FontWeight.w700, headingHeight, onSurface),
      titleLarge: s(titleLarge, FontWeight.w700, headingHeight, onSurface),
      titleMedium: s(titleMedium, FontWeight.w600, titleHeight, onSurface),
      titleSmall: s(titleSmall, FontWeight.w600, titleHeight, onSurface),
      bodyLarge: s(bodyLarge, FontWeight.w400, bodyHeight, onSurface),
      bodyMedium: s(bodyMedium, FontWeight.w400, bodyHeight, onSurface),
      bodySmall: s(bodySmall, FontWeight.w400, captionHeight, onSurfaceVariant),
      labelLarge: s(labelLarge, FontWeight.w600, labelHeight, onSurface),
      labelMedium: s(labelMedium, FontWeight.w600, labelHeight, onSurface),
      labelSmall: s(11, FontWeight.w500, labelHeight, onSurfaceVariant),
    );
  }

  /// 到站時間樣式。
  static const TextStyle arrivalTimeStyle = TextStyle(
    fontSize: arrivalTime,
    fontWeight: FontWeight.w700,
    height: 1.0,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
