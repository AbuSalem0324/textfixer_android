import 'package:flutter/services.dart';

class ClipboardService {
  static const int _minTextLength = 10;
  static const int _maxTextLength = 500; // Default for free tier
  static const double _minAlphaRatio = 0.3;
  static const int _defaultPreviewLength = 100;

  /// Get current clipboard content
  static Future<String?> getCurrentClipboardText() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      return clipboardData?.text?.trim();
    } catch (e) {
      return null;
    }
  }

  /// Replace clipboard with fixed text
  static Future<void> setClipboardText(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      throw Exception('Failed to copy text to clipboard');
    }
  }

  /// Check if clipboard has text content
  static Future<bool> hasTextInClipboard() async {
    try {
      final text = await getCurrentClipboardText();
      return text != null && text.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get clipboard preview (first N characters)
  static String getClipboardPreview(String text,
      {int maxLength = _defaultPreviewLength}) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  /// Check if text is worth processing (default free tier limit)
  static bool isTextWorthFixing(String text) {
    return isTextWorthFixingWithLimit(text, _maxTextLength);
  }

  /// Check if text is worth processing with custom character limit
  static bool isTextWorthFixingWithLimit(String text, int maxLength) {
    final trimmed = text.trim();

    // Length validation
    if (trimmed.length < _minTextLength) {
      return false;
    }

    if (trimmed.length > maxLength) {
      return false;
    }

    // Check alphabetic character ratio
    final alphaCount = trimmed.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    return alphaCount >= trimmed.length * _minAlphaRatio;
  }

  /// Get character limit error message
  static String getCharacterLimitMessage(String text, int limit) {
    final length = text.trim().length;
    if (length < _minTextLength) {
      return 'Text too short. Minimum $_minTextLength characters required.';
    }
    if (length > limit) {
      return 'Text too long. Maximum $limit characters allowed for your plan.';
    }
    return 'Text doesn\'t contain enough readable content.';
  }
}
