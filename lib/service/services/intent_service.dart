import 'package:flutter/services.dart';

class IntentService {
  static const MethodChannel _platform =
      MethodChannel('com.textfixer.android/intent');

  /// Get text from Android intent (share menu or text selection)
  static Future<String?> getIntentText() async {
    try {
      final String? text = await _platform.invokeMethod('getIntentText');
      return text;
    } catch (e) {
      print('Error getting intent text: $e');
      return null;
    }
  }

  /// Close the Android app
  static void closeApp() {
    SystemNavigator.pop();
  }

  /// Copy text to clipboard
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
