import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class ToastService {
  /// Show a regular toast message
  static void showToast(String message, {bool isLoading = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: isLoading ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: Color(0xFFA45C40),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Show a success toast
  static void showSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Show an error toast
  static void showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
