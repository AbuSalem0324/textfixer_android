import 'dart:convert';
import 'package:http/http.dart' as http;
import 'services/device_info_service.dart';

class ApiService {
  // Production URL - v2 Backend
  static const String baseUrl = 'https://textfixer-backend-v2.onrender.com';

  // Local development URL (commented for production)
  // static const String baseUrl = 'http://10.0.2.2:8000';

  static const Duration _timeout = Duration(seconds: 30);

  Future<Map<String, dynamic>> fixText(String apiKey, String text) async {
    try {
      final deviceHeaders = await DeviceInfoService.getDeviceHeaders();

      final headers = {
        'X-API-Key': apiKey,
        'X-Client-Type': 'android',
        'X-Client-Version': '2.1.2',
        'X-Platform': 'Android',
        ...deviceHeaders,
      };

      // Send text as query parameter (FastAPI expects it as query param without Form() annotation)
      final uri = Uri.parse('$baseUrl/api/text/fix').replace(
        queryParameters: {'text': text},
      );

      final response = await http
          .post(
            uri,
            headers: headers,
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
    // V2 Backend response format
    final processedText = data['processed_text'] ?? originalText;

    return {
      'fixedText': processedText,
      'userMessage': data['improvements_made'] ?? 'Text corrected successfully!',
      'model': data['model_used'],
      'originalLength': originalText.length,
      'fixedLength': processedText.length,
      // Usage tracking data
      'usageSummary': data['usage_summary'],
      'remainingQuota': data['remaining_quota'],
      'limits': data['limits'],
      'subscriptionTier': data['subscription_tier'],
    };
  }

  Map<String, dynamic> _handleErrorResponse(
      int statusCode, Map<String, dynamic> data) {
    // V2 Backend uses 'detail' field for error messages
    String userMessage = data['detail'] ?? '';

    // If no specific error message, provide fallback based on status code
    if (userMessage.isEmpty) {
      switch (statusCode) {
        case 429:
          userMessage = 'Request limit reached. Please try again later.';
          break;
        case 413:
          userMessage = 'Text too long for your subscription tier.';
          break;
        case 400:
          userMessage = 'Invalid request. Please check your text.';
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
    }

    throw Exception(userMessage);
  }

  Future<Map<String, dynamic>> registerFreeAccount(String email) async {
    try {
      final deviceHeaders = await DeviceInfoService.getDeviceHeaders();

      final headers = {
        'Content-Type': 'application/json',
        'X-Client-Type': 'android',
        'X-Client-Version': '2.1.2',
        'X-Platform': 'Android',
        ...deviceHeaders,
      };

      // V2 Backend simplified registration request
      final body = {
        'email': email,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/users/register'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // V2 Backend returns 201 Created on successful registration
        return {
          'success': true,
          'apiKey': data['api_key'] ?? '',
          'userId': data['user']?['id'] ?? '',
          'email': data['user']?['email'] ?? email,
          'message': 'Account created! Check your email for your access code.',
        };
      }

      return _handleRegistrationError(response.statusCode, data);
    } catch (e) {
      throw Exception(_getNetworkErrorMessage(e));
    }
  }

  Map<String, dynamic> _handleRegistrationError(
      int statusCode, Map<String, dynamic> data) {
    // V2 Backend uses 'detail' field for error messages
    String userMessage = data['detail'] ?? '';

    // If no specific error message, provide fallback based on status code
    if (userMessage.isEmpty) {
      switch (statusCode) {
        case 400:
          userMessage = 'Invalid email address. Please check and try again.';
          break;
        case 409:
          userMessage = 'This email is already registered. Try logging in instead.';
          break;
        case 429:
          userMessage = 'Too many registration attempts. Please try again later.';
          break;
        case 500:
        case 502:
        case 503:
          userMessage =
              'Service temporarily unavailable. Please try again in a moment.';
          break;
        default:
          userMessage = 'Failed to create account. Please try again.';
      }
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
