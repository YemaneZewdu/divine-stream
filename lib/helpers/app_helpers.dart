import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

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

  /// Shows a platform-aware confirmation dialog and returns true when the user
  /// accepts the action.
  static Future<bool> showPlatformConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
  }) async {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      final result = await showCupertinoDialog<bool>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: Text(cancelLabel),
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(confirmLabel),
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            ),
          ],
        ),
      );
      return result ?? false;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: Text(cancelLabel),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(confirmLabel),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
