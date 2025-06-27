import 'package:flutter/services.dart';

class ClipboardService {
  /// Get current clipboard content
  static Future<String?> getCurrentClipboardText() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      return clipboardData?.text;
    } catch (e) {
      print('Error getting clipboard text: $e');
      return null;
    }
  }

  /// Replace clipboard with fixed text
  static Future<void> setClipboardText(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      print('Error setting clipboard text: $e');
      throw Exception('Failed to copy text to clipboard');
    }
  }

  /// Check if clipboard has text content
  static Future<bool> hasTextInClipboard() async {
    try {
      final text = await getCurrentClipboardText();
      return text != null && text.trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get clipboard preview (first N characters)
  static String getClipboardPreview(String text, {int maxLength = 100}) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  /// Check if text is worth processing
  static bool isTextWorthFixing(String text) {
    final trimmed = text.trim();

    // Too short
    if (trimmed.length < 10) return false;

    // Too long (over 5000 characters)
    if (trimmed.length > 5000) return false;

    // Contains mostly non-alphabetic characters
    final alphaCount = trimmed.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (alphaCount < trimmed.length * 0.3) return false;

    return true;
  }
}
