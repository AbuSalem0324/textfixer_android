import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static Map<String, String>? _cachedHeaders;

  static Future<Map<String, String>> getDeviceHeaders() async {
    if (_cachedHeaders != null) {
      return _cachedHeaders!;
    }

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _cachedHeaders = {
          'X-Device-Model': androidInfo.model,
          'X-Device-Brand': androidInfo.brand,
          'X-Device-Manufacturer': androidInfo.manufacturer,
          'X-OS-Version': 'Android ${androidInfo.version.release}',
          'X-SDK-Int': androidInfo.version.sdkInt.toString(),
          'X-Device-ID': androidInfo.id,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _cachedHeaders = {
          'X-Device-Model': iosInfo.model,
          'X-Device-Name': iosInfo.name,
          'X-OS-Version': 'iOS ${iosInfo.systemVersion}',
          'X-Device-ID': iosInfo.identifierForVendor ?? 'unknown',
        };
      } else {
        _cachedHeaders = {
          'X-Device-Model': 'unknown',
          'X-OS-Version': Platform.operatingSystem,
          'X-Device-ID': 'unknown',
        };
      }
    } catch (e) {
      _cachedHeaders = {
        'X-Device-Model': 'unknown',
        'X-OS-Version': Platform.operatingSystem,
        'X-Device-ID': 'unknown',
      };
    }

    return _cachedHeaders!;
  }

  static void clearCache() {
    _cachedHeaders = null;
  }
}