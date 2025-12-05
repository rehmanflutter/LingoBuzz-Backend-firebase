import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingobuzz/core/common/snackbar_utils.dart';

import '../app_text.dart';
import '../utils/Themes/app_color.dart';

/// Helper class to handle battery optimization settings
/// This is CRITICAL for background tasks to work reliably on Android 6.0+
class BatteryOptimizationHelper {
  static const platform = MethodChannel('com.lingobuzz.app/battery');

  /// Check if battery optimization is ignored
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;

    try {
      final bool result = await platform.invokeMethod('isIgnoringBatteryOptimizations');
      return result;
    } on PlatformException catch (e) {
      debugPrint("Error checking battery optimization: ${e.message}");
      return false;
    }
  }

  /// Request to ignore battery optimizations
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;

    try {
      final bool result = await platform.invokeMethod('requestIgnoreBatteryOptimizations');
      return result;
    } on PlatformException catch (e) {
      debugPrint("Error requesting battery optimization: ${e.message}");
      return false;
    }
  }

  /// Show dialog to user explaining why we need this permission
  static Future<void> showBatteryOptimizationDialog(BuildContext context) async {
    final isIgnoring = await isIgnoringBatteryOptimizations();

    if (isIgnoring) {
      if (context.mounted) {
        SnackBarUtils.showInfoSnackbar('Battery optimization already disabled');
      }
      return;
    }

    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: const CustomTextWidget( title: '⚡ Battery Optimization',),
          content: const CustomTextWidget( title:
          'To receive word updates in the background, please disable battery optimization for LingoBuzz.\n\n'
                'This allows the app to:\n'
                '• Update your widget automatically\n'
                '• Send word notifications on schedule\n'
                '• Keep learning sessions on time',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const CustomTextWidget( title: 'Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final granted = await requestIgnoreBatteryOptimizations();

                if (context.mounted) {
                  granted ?
                  SnackBarUtils.showSuccessSnackbar('Battery optimization disabled'):
                  SnackBarUtils.showInfoSnackbar('Permission denied. Background updates may not work.');
                }
              },
              child: const CustomTextWidget( title: 'Allow'),
            ),
          ],
        );
      },
    );
  }

  /// Check and request if needed
  static Future<void> checkAndRequest(BuildContext context) async {
    final isIgnoring = await isIgnoringBatteryOptimizations();

    if (!isIgnoring && context.mounted) {
      await showBatteryOptimizationDialog(context);
    }
  }
}