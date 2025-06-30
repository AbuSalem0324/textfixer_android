import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://textfixer.onrender.com';
  static const Duration _timeout = Duration(seconds: 30);

  Future<Map<String, dynamic>> fixText(String apiKey, String text) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/fix'),
            headers: {
              'Content-Type': 'application/json',
              'X-API-Key': apiKey,
            },
            body: jsonEncode({'text': text}),
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return _handleSuccessResponse(data, text);
      }

      return _handleErrorResponse(response.statusCode, data);
    } catch (e) {
      throw Exception(_getNetworkErrorMessage(e));
    }
  }

  Map<String, dynamic> _handleSuccessResponse(
      Map<String, dynamic> data, String originalText) {
    // Check for custom headers with user messages
    final headers = data['_headers'];
    if (headers != null) {
      return {
        'fixedText':
            headers['fixedTextRaw'] ?? data['fixedText'] ?? originalText,
        'userMessage': headers['messageRaw'] ?? 'Text corrected successfully!',
        'model': data['model'],
        'originalLength': data['originalLength'],
        'fixedLength': data['fixedLength'],
      };
    }

    // Fallback to regular response
    return {
      'fixedText': data['fixedText'] ?? originalText,
      'userMessage': 'Text corrected successfully!',
      'model': data['model'],
      'originalLength': data['originalLength'],
      'fixedLength': data['fixedLength'],
    };
  }

  Map<String, dynamic> _handleErrorResponse(
      int statusCode, Map<String, dynamic> data) {
    final headers = data['_headers'];
    String userMessage;

    switch (statusCode) {
      case 429:
        userMessage = headers?['messageRaw'] ??
            'Monthly limit reached. Upgrade to Pro for unlimited fixes.';
        break;
      case 400:
        userMessage = headers?['messageRaw'] ??
            'Invalid request. Please check your text.';
        break;
      case 401:
        userMessage = 'Invalid API key. Please check your access code.';
        break;
      case 500:
      case 502:
      case 503:
        userMessage =
            'Service temporarily unavailable. Please try again in a moment.';
        break;
      default:
        userMessage = 'Failed to fix text. Please try again.';
    }

    throw Exception(userMessage);
  }

  String _getNetworkErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socketexception') ||
        errorString.contains('timeoutexception') ||
        errorString.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }

    // Re-throw our custom exceptions as-is
    if (error.toString().startsWith('Exception:')) {
      throw error;
    }

    return 'Connection error. Please try again.';
  }
}
