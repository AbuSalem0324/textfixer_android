import 'dart:async';
import '/api_service.dart';
import '/storage_service.dart';
import '/models/clipboard_processing_result.dart';
import 'intent_service.dart';
import 'toast_service.dart';
import 'clipboard_service.dart';

class TextProcessingService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  /// Process text without auto-closing (for loading screen control)
  Future<void> processTextWithoutClosing(String text) async {
    final apiKey = await _storage.getApiKey();

    if (apiKey == null) {
      ToastService.showError('API key not found. Please set up TextFixer.');
      throw Exception('No API key');
    }

    try {
      final result = await _api.fixText(apiKey, text);

      // Copy to clipboard
      await IntentService.copyToClipboard(result['fixedText']);

      // Show success toast with longer duration
      ToastService.showSuccessLong(
          result['userMessage'] ?? 'Text fixed and copied to clipboard!');
    } catch (e) {
      // Show error toast
      String errorMessage = _formatErrorMessage(e.toString());
      ToastService.showError(errorMessage);

      // Re-throw to let caller handle
      throw e;
    }
  }

  /// Enhanced clipboard processing with result management
  Future<ClipboardProcessingResult> processClipboardTextWithResult() async {
    final apiKey = await _storage.getApiKey();

    if (apiKey == null) {
      throw Exception('API key not found. Please set up TextFixer.');
    }

    // Get clipboard text
    final originalText = await ClipboardService.getCurrentClipboardText();

    if (originalText == null || originalText.trim().isEmpty) {
      throw Exception('No text found in clipboard');
    }

    // Check if text is worth processing
    if (!ClipboardService.isTextWorthFixing(originalText)) {
      throw Exception(
          'Text is too short or doesn\'t contain enough readable content');
    }

    try {
      // Process with API
      final result = await _api.fixText(apiKey, originalText);

      // Return structured result for UI handling
      return ClipboardProcessingResult(
        originalText: originalText,
        fixedText: result['fixedText'] ?? originalText,
        userMessage: result['userMessage'] ?? 'Text processed successfully',
        model: result['model'],
        originalLength: result['originalLength'],
        fixedLength: result['fixedLength'],
      );
    } catch (e) {
      // Show error toast
      String errorMessage = _formatErrorMessage(e.toString());
      ToastService.showError(errorMessage);

      // Re-throw to let caller handle
      throw Exception(errorMessage);
    }
  }

  /// Re-process already edited text
  Future<ClipboardProcessingResult> refixText(String textToRefix) async {
    final apiKey = await _storage.getApiKey();

    if (apiKey == null) {
      throw Exception('API key not found. Please set up TextFixer.');
    }

    if (textToRefix.trim().isEmpty) {
      throw Exception('No text to process');
    }

    try {
      final result = await _api.fixText(apiKey, textToRefix);

      return ClipboardProcessingResult(
        originalText: textToRefix,
        fixedText: result['fixedText'] ?? textToRefix,
        userMessage: result['userMessage'] ?? 'Text re-processed successfully',
        model: result['model'],
        originalLength: result['originalLength'],
        fixedLength: result['fixedLength'],
      );
    } catch (e) {
      // Show error toast
      String errorMessage = _formatErrorMessage(e.toString());
      ToastService.showError(errorMessage);

      // Re-throw to let caller handle
      throw Exception(errorMessage);
    }
  }

  /// Format error message for user display
  String _formatErrorMessage(String error) {
    if (error.contains('Network') || error.contains('Connection')) {
      return 'Network error. Please try again.';
    }
    return error.replaceAll('Exception: ', '');
  }
}
