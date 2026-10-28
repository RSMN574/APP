import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';

import 'package:com.rsmn574.app/const/app_colors.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';

/// 公車功能共用的 QuickAlert：套用深色／淺色主題色與目前語言的按鈕文字。
void showBusQuickAlert(
  BuildContext context, {
  required QuickAlertType type,
  String? title,
  String? text,
  Color? confirmBtnColor,
  String? confirmBtnText,
  String? cancelBtnText,
  QuickAlertAnimType animType = QuickAlertAnimType.scale,
  bool showCancelBtn = false,
  VoidCallback? onConfirmBtnTap,
  VoidCallback? onCancelBtnTap,
}) {
  final l10n = AppLocalizations.of(context)!;
  final appColors = context.appColors;
  final colorScheme = Theme.of(context).colorScheme;
  final btnColor = confirmBtnColor ?? colorScheme.primary;
  final btnTextColor =
      btnColor.computeLuminance() > 0.6 ? Colors.black87 : Colors.white;

  QuickAlert.show(
    context: context,
    type: type,
    title: title,
    text: text,
    animType: animType,
    showCancelBtn: showCancelBtn,
    confirmBtnText: confirmBtnText ?? l10n.text_471,
    cancelBtnText: cancelBtnText ?? l10n.text_36,
    confirmBtnColor: btnColor,
    confirmBtnTextStyle: TextStyle(
      color: btnTextColor,
      fontWeight: FontWeight.w600,
      fontSize: 18.0,
    ),
    cancelBtnTextStyle: TextStyle(
      color: appColors.textSecondary,
      fontWeight: FontWeight.w600,
      fontSize: 18.0,
    ),
    backgroundColor: appColors.cardBackground,
    headerBackgroundColor: appColors.cardBackground,
    titleColor: appColors.textPrimary,
    textColor: appColors.textPrimary,
    onConfirmBtnTap: onConfirmBtnTap,
    onCancelBtnTap: onCancelBtnTap,
  );
}
