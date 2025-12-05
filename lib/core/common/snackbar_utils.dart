import 'package:flutter/material.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'app_keys.dart';

class SnackBarUtils {
  static void _showSnackbar({
    required String message,
    required Color background,
    required Color textColor,
    required IconData icon,
    required Color borderColor,
  }) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      backgroundColor: background,
      elevation: 0, // keep it flat for outlined look
      content: Row(
        children: [
          Icon(icon, color: textColor, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: CustomTextWidget(
              color: textColor, fontSize: 16,
              title: message,
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.2),
      ),
    );

    scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }

  static void showErrorSnackbar(String message) {
    _showSnackbar(
      message: message,
      background: Colors.red.shade50,
      textColor: Colors.red.shade900,
      borderColor: Colors.red.shade200,
      icon: Icons.error_outline,
    );
  }

  static void showSuccessSnackbar(String message) {
    _showSnackbar(
      message: message,
      background: Colors.green.shade50,
      textColor: Colors.green.shade900,
      borderColor: Colors.green.shade200,
      icon: Icons.check_circle_outline,
    );
  }

  static void showInfoSnackbar(String message) {
    _showSnackbar(
      message: message,
      background: Colors.orange.shade50,
      textColor: Colors.orange.shade900,
      borderColor: Colors.orange.shade200,
      icon: Icons.info_outline,
    );
  }
}
