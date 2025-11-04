import 'package:flutter/material.dart';

class CustomSnackbar {
  // 🔹 Generic method for showing snackbar
  static void show(
      BuildContext context,
      String message, {

        Color backgroundColor = Colors.black,
        Color textColor = Colors.white,
        Duration duration = const Duration(seconds: 3),
        IconData? icon,
      }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    );

    // 🔹 Remove current snackbar if any
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
