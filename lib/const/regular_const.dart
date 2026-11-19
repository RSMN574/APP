import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'arrival_status_colors.dart';
import 'app_design_tokens.dart';

const Color primary = Color.fromRGBO(0, 125, 254, 1);
const Color secondary = Color.fromRGBO(38, 38, 38, 1);
const Color blue = Color.fromRGBO(36, 137, 243, 1);
const Color busBlue = Color.fromRGBO(2, 101, 143, 1);
const Color startColor = Color.fromARGB(255, 13, 193, 255);
const Color endColor = Color.fromARGB(255, 27, 141, 255);
const Color bgColor = Color.fromRGBO(245, 245, 245, 1);
const Color bgColorWhite = Colors.white;

class AppThemes {
  // 設計基準：淺色 Primary #1A73E8 / Background #F8FAFD / Surface #EEF3FB；
  // 深色 Primary #64B5F6。顏色只在這裡與 AppColors 定義，各頁面請透過
  // Theme.of(context).colorScheme 或 context.appColors 取用。
  static const Color _brandBlue = AppColors.primaryBlue;
  static const Color _brandBlueDark = Color(0xFF64B5F6);
  static const Color _onBrandBlueDark = Color(0xFF00213D);
  static const Color _lightBackground = AppColors.backgroundLight;
  static const Color _lightSurface = AppColors.surfaceColor;
  // OLED 友善的近黑背景；卡片 #1C1C1E、Dialog/BottomSheet #1E1E20、
  // 最高層 #2C2C2E 逐層提亮，維持深色階層。
  static const Color _darkSurface = Color(0xFF0B0B0D);

  static Color getPrimary(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color getDropdownMenuColor(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerHigh;
  }

  static Color getHighlightColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary.withValues(alpha: 0.12);
  }

  static Color getSurface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getOnSurface(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color? getCardColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLow;
  }

  static NavigationBarThemeData getNavigationBarTheme(BuildContext context) {
    return Theme.of(context).navigationBarTheme;
  }

  static InputDecorationThemeData inputTheme(BuildContext context) {
    return Theme.of(context).inputDecorationTheme;
  }

  static Color getInputFillColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.inputDecorationTheme.fillColor ??
        theme.colorScheme.surfaceContainerHighest;
  }

  static AppBarThemeData getAppBarTheme(BuildContext context) {
    return Theme.of(context).appBarTheme;
  }

  static final ThemeData lightTheme = _createTheme(Brightness.light);
  static final ThemeData darkTheme = _createTheme(Brightness.dark);

  static ThemeData _createTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandBlue,
      brightness: brightness,
      // 深色模式使用較亮的 #64B5F6，在深色底上才有足夠對比；
      // 其上的文字/圖示改用深藍，避免白字在淺藍底上對比不足。
      primary: isDark ? _brandBlueDark : _brandBlue,
      onPrimary: isDark ? _onBrandBlueDark : Colors.white,
      surface: isDark ? _darkSurface : _lightBackground,
      onSurface: isDark ? const Color(0xFFF2F2F7) : const Color(0xFF1C1C1E),
      surfaceContainer: isDark ? const Color(0xFF1E1E20) : _lightSurface,
      surfaceContainerHighest: isDark ? const Color(0xFF2C2C2E) : _lightSurface,
      secondary: isDark ? const Color(0xFF9FB0CC) : const Color(0xFF5B6B85),
      tertiary: isDark ? const Color(0xFF4DB6AC) : const Color(0xFF00796B),
    );
    final appColors = isDark ? AppColors.dark : AppColors.light;
    final cardColor = appColors.cardBackground;
    // 按鈕、輸入框圓角 12；卡片、Dialog、BottomSheet 圓角 20。
    final borderRadius = BorderRadius.circular(AppRadius.md);
    final cardRadius = BorderRadius.circular(AppRadius.xl);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[
        appColors,
        isDark ? ArrivalStatusColors.dark : ArrivalStatusColors.light,
      ],
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: AppTypography.titleLarge,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      // 由 AppTypography 產生，避免與 Token 矛盾（原 body 18/16、title 22）。
      textTheme: AppTypography.textTheme(
        onSurface: colorScheme.onSurface,
        onSurfaceVariant: colorScheme.onSurfaceVariant,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageMargin,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          disabledForegroundColor:
              colorScheme.onSurface.withValues(alpha: 0.38),
          disabledBackgroundColor:
              colorScheme.onSurface.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          elevation: isDark ? 0 : 1,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          minimumSize: const Size(48, 48),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          // 確保觸控範圍至少 48x48（Material / TalkBack 建議值）。
          minimumSize: const Size(48, 48),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontSize: AppTypography.labelLarge,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: AppTypography.labelLarge,
          fontWeight: FontWeight.w500,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: cardColor,
        indicatorColor: colorScheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: selected ? 12 : 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color:
                selected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            letterSpacing: 0.2,
          );
        }),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainer),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: WidgetStatePropertyAll(isDark ? 0 : 4),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 8,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colorScheme.surfaceContainer,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        actionTextColor: colorScheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
    );
  }
}
