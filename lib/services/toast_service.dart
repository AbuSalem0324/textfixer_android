import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class ToastService {
  // Brand colors as constants
  static const Color _brandColor = Color(0xFFA45C40);
  static const Color _successColor = Color(0xFF4CAF50);
  static const Color _errorColor = Color(0xFFE53935);
  static const double _fontSize = 16.0;
  static const ToastGravity _gravity = ToastGravity.TOP;

  /// Show a regular toast message
  static void showToast(String message, {bool isLoading = false}) {
    _showToast(
      message: message,
      backgroundColor: _brandColor,
      duration: isLoading ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
    );
  }

  /// Show a success toast (short duration)
  static void showSuccess(String message) {
    _showToast(
      message: message,
      backgroundColor: _successColor,
      duration: Toast.LENGTH_SHORT,
    );
  }

  /// Show a success toast with longer duration for important messages
  static void showSuccessLong(String message) {
    _showToast(
      message: message,
      backgroundColor: _successColor,
      duration: Toast.LENGTH_LONG,
    );
  }

  /// Show an error toast (always long duration)
  static void showError(String message) {
    _showToast(
      message: message,
      backgroundColor: _errorColor,
      duration: Toast.LENGTH_LONG,
    );
  }

  /// Private method to reduce code duplication
  static void _showToast({
    required String message,
    required Color backgroundColor,
    required Toast duration,
  }) {
    // Limit message length to prevent UI issues
    final displayMessage =
        message.length > 120 ? '${message.substring(0, 117)}...' : message;

    Fluttertoast.showToast(
      msg: displayMessage,
      toastLength: duration,
      gravity: _gravity,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: _fontSize,
    );
  }
}
