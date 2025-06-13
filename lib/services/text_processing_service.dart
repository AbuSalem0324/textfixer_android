import 'dart:async';
import '/api_service.dart';
import '/storage_service.dart';
import 'intent_service.dart';
import 'toast_service.dart';

class TextProcessingService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  /// Process text in background for intent-based usage
  Future<void> processTextInBackground(String text) async {
    final apiKey = await _storage.getApiKey();

    if (apiKey == null) {
      ToastService.showError('API key not found. Please set up TextFixer.');
      return;
    }

    try {
      ToastService.showToast('Fixing text...', isLoading: true);

      final result = await _api.fixText(apiKey, text);

      // Copy to clipboard
      await IntentService.copyToClipboard(result['fixedText']);

      // Show success toast
      ToastService.showSuccess(
          result['userMessage'] ?? 'Text fixed and copied to clipboard!');
    } catch (e) {
      // Show error toast
      String errorMessage = _formatErrorMessage(e.toString());
      ToastService.showError(errorMessage);
    }
    // Note: We don't close the app here anymore - it's handled by the caller
  }

  /// Test text processing functionality
  Future<void> testTextProcessing() async {
    await processTextInBackground("This is a test text with erors to fix.");
  }

  /// Format error message for user display
  String _formatErrorMessage(String error) {
    if (error.contains('Network') || error.contains('Connection')) {
      return 'Network error. Please try again.';
    }
    return error.replaceAll('Exception: ', '');
  }
}
