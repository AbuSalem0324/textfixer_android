import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://textfixer.onrender.com';

  Future<Map<String, dynamic>> fixText(String apiKey, String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fix'),
        headers: {'Content-Type': 'application/json', 'X-API-Key': apiKey},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check for custom headers with user messages
        final headers = data['_headers'];
        if (headers != null) {
          final messageRaw = headers['messageRaw'];
          final fixedTextRaw = headers['fixedTextRaw'];

          return {
            'fixedText': fixedTextRaw ?? data['fixedText'] ?? text,
            'userMessage': messageRaw ?? 'Text corrected successfully!',
            'model': data['model'],
            'originalLength': data['originalLength'],
            'fixedLength': data['fixedLength'],
          };
        }

        // Fallback to regular response
        return {
          'fixedText': data['fixedText'] ?? text,
          'userMessage': 'Text corrected successfully!',
          'model': data['model'],
          'originalLength': data['originalLength'],
          'fixedLength': data['fixedLength'],
        };
      } else if (response.statusCode == 429) {
        // Quota exceeded
        final data = jsonDecode(response.body);
        final headers = data['_headers'];
        final userMessage = headers?['messageRaw'] ??
            'Monthly limit reached. Upgrade to Pro for unlimited fixes.';

        throw Exception(userMessage);
      } else if (response.statusCode == 400) {
        // Validation error
        final data = jsonDecode(response.body);
        final headers = data['_headers'];
        final userMessage = headers?['messageRaw'] ??
            'Invalid request. Please check your text.';

        throw Exception(userMessage);
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your access code.');
      } else if (response.statusCode >= 500) {
        throw Exception(
          'Service temporarily unavailable. Please try again in a moment.',
        );
      } else {
        throw Exception('Failed to fix text. Please try again.');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        throw Exception(
          'Network error. Please check your internet connection.',
        );
      }

      // Re-throw our custom exceptions
      if (e.toString().startsWith('Exception:')) {
        rethrow;
      }

      throw Exception('Connection error. Please try again.');
    }
  }
}
