import 'package:fluttertoast/fluttertoast.dart';
import 'dart:ui';

import 'app_colors.dart';

class Helpers {
  static void showToast(
    String message, {
    Toast length = Toast.LENGTH_SHORT,
    ToastGravity gravity = ToastGravity.CENTER,
    int timeInSecForIosWeb = 1,
    Color? backgroundColor = kcErrorColor,
    Color textColor = kcWhite,
    double fontSize = 16.0,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: length,
      gravity: gravity,
      timeInSecForIosWeb: timeInSecForIosWeb,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: fontSize,
    );
  }

  static String? extractFolderIdFromUrl(String url) {
    final regex = RegExp(r'drive\/folders\/([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  static String shorten(String text, [int maxLength = 100]) {
    return text.length <= maxLength
        ? text
        : text.substring(0, maxLength) + '...';
  }
}
