import 'package:flutter/material.dart';
import 'package:shopspot/utils/app_colors.dart';

Color getSuccessColor(context) {
  bool isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? AppColors.successDark : AppColors.successLight;
}

Color getWarningColor(context) {
  bool isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? AppColors.warningDark : AppColors.warningLight;
}
