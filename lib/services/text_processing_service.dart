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
    final apiKey = await _getApiKeyOrThrow();

    try {
      final result = await _api.fixText(apiKey, text);
      await IntentService.copyToClipboard(result['fixedText']);
      ToastService.showSuccessLong(
          result['userMessage'] ?? 'Text fixed and copied to clipboard!');
    } catch (e) {
      _handleAndRethrowError(e);
    }
  }

  /// Enhanced clipboard processing with result management
  Future<ClipboardProcessingResult> processClipboardTextWithResult() async {
    final apiKey = await _getApiKeyOrThrow();
    final originalText = await _getValidClipboardText();

    return await _processTextAndCreateResult(
        apiKey, originalText, 'Text processed successfully');
  }

  /// Re-process already edited text
  Future<ClipboardProcessingResult> refixText(String textToRefix) async {
    final apiKey = await _getApiKeyOrThrow();

    if (textToRefix.trim().isEmpty) {
      throw Exception('No text to process');
    }

    return await _processTextAndCreateResult(
        apiKey, textToRefix, 'Text re-processed successfully');
  }

  /// Get API key or throw appropriate exception
  Future<String> _getApiKeyOrThrow() async {
    final apiKey = await _storage.getApiKey();
    if (apiKey == null) {
      ToastService.showError('API key not found. Please set up TextFixer.');
      throw Exception('No API key');
    }
    return apiKey;
  }

  /// Get valid clipboard text or throw appropriate exception
  Future<String> _getValidClipboardText() async {
    final originalText = await ClipboardService.getCurrentClipboardText();

    if (originalText == null || originalText.trim().isEmpty) {
      throw Exception('No text found in clipboard');
    }

    if (!ClipboardService.isTextWorthFixing(originalText)) {
      throw Exception(
          'Text is too short or doesn\'t contain enough readable content');
    }

    return originalText;
  }

  /// Process text with API and create result object
  Future<ClipboardProcessingResult> _processTextAndCreateResult(
    String apiKey,
    String originalText,
    String defaultMessage,
  ) async {
    try {
      final result = await _api.fixText(apiKey, originalText);

      return ClipboardProcessingResult(
        originalText: originalText,
        fixedText: result['fixedText'] ?? originalText,
        userMessage: result['userMessage'] ?? defaultMessage,
        model: result['model'],
        originalLength: result['originalLength'],
        fixedLength: result['fixedLength'],
      );
    } catch (e) {
      _handleAndRethrowError(e);
    }
  }

  /// Handle errors consistently and rethrow
  Never _handleAndRethrowError(dynamic error) {
    final errorMessage = _formatErrorMessage(error.toString());
    ToastService.showError(errorMessage);
    throw Exception(errorMessage);
  }

  /// Format error message for user display
  String _formatErrorMessage(String error) {
    final cleanError = error.replaceAll('Exception: ', '');

    if (cleanError.toLowerCase().contains('network') ||
        cleanError.toLowerCase().contains('connection')) {
      return 'Network error. Please try again.';
    }

    return cleanError;
  }
}
