import 'dart:async';
import '/api_service.dart';
import '/storage_service.dart';
import 'intent_service.dart';
import 'toast_service.dart';

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

  /// Format error message for user display
  String _formatErrorMessage(String error) {
    if (error.contains('Network') || error.contains('Connection')) {
      return 'Network error. Please try again.';
    }
    return error.replaceAll('Exception: ', '');
  }
}
