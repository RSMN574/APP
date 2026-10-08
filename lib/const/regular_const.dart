import 'package:flutter/material.dart';

const Color primary = Color.fromRGBO(0, 125, 254, 1);
const Color secondary = Color.fromRGBO(38, 38, 38, 1);
const Color blue = Color.fromRGBO(36, 137, 243, 1);
const Color busBlue = Color.fromRGBO(2, 101, 143, 1);
const Color startColor = Color.fromARGB(255, 13, 193, 255);
const Color endColor = Color.fromARGB(255, 27, 141, 255);
const Color bgColor = Color.fromRGBO(245, 245, 245, 1);
const Color bgColorWhite = Colors.white;

class AppThemes {
  static const Color _brandBlue = Color(0xFF1A73E8);
  static const Color _darkSurface = Color(0xFF121212);

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
      primary: _brandBlue,
      onPrimary: Colors.white,
      surface: isDark ? _darkSurface : const Color(0xFFFAFAFC),
      onSurface: isDark ? const Color(0xFFF2F2F7) : const Color(0xFF1C1C1E),
      surfaceContainerHighest:
          isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F1F4),
    );
    final cardColor =
        isDark ? colorScheme.surfaceContainer : colorScheme.surface;
    final borderRadius = BorderRadius.circular(12);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: 18, color: colorScheme.onSurface),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
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
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colorScheme.surfaceContainer,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
