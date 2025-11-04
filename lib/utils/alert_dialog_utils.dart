import 'package:flutter/material.dart';

class AlertDialogUtils {
  /// 🔹 Universal Confirm Dialog
  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    required Widget content,
    Color? confirmColor,
    Color? cancelColor,
    String confirmText = "Confirm",
    String cancelText = "Cancel",
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: content,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText, style: const TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: TextStyle(color: confirmColor ?? Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
