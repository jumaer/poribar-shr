import 'package:flutter/material.dart';

class AppDimensions {
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  static double widthPercentage(BuildContext context, double percentage) =>
      screenWidth(context) * (percentage / 100);

  static double heightPercentage(BuildContext context, double percentage) =>
      screenHeight(context) * (percentage / 100);

  static double paddingSmall = 8.0;
  static double paddingMedium = 16.0;
  static double paddingLarge = 24.0;

  static double radiusSmall = 10.0;
  static double radiusMedium = 16.0;
  static double radiusLarge = 24.0;
}
