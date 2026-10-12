import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bluebug/utils/constants.dart';

void main() {
  test('uses the configured LAN host by default for Android', () {
    expect(
      AppConstants.resolveBaseUrl(serverIp: null, isAndroid: true),
      'http://10.0.2.2:4000',
    );
  });

  test('uses localhost for non-Android platforms when no server IP is set', () {
    expect(
      AppConstants.resolveBaseUrl(serverIp: null, isAndroid: false),
      'http://127.0.0.1:4000',
    );
  });

  test('uses the provided server IP when available', () {
    expect(
      AppConstants.resolveBaseUrl(serverIp: '192.168.1.50', isAndroid: true),
      'http://192.168.1.50:4000',
    );
  });

  test('persists a saved server IP for future app runs', () async {
    SharedPreferences.setMockInitialValues({});
    await AppConstants.setServerIp('192.168.1.100');
    expect(AppConstants.baseUrl, 'http://192.168.1.100:4000');
  });
}
