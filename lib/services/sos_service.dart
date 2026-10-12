import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SosService {
  static String get _baseUrl => '${AppConstants.baseUrl}/api';
  static const String _nativeChannel = 'com.example.bluebug_app/sos';

  // ── AUDIO ──
  static final AudioPlayer _player = AudioPlayer();
  static bool _sirenPlaying = false;
  static int? _activeSosId;

  static Future<void> startSiren() async {
    if (_sirenPlaying) return;
    _sirenPlaying = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      await _player.play(AssetSource('audio/siren.mp3'));
    } catch (_) {}
  }

  static Future<void> stopSiren() async {
    _sirenPlaying = false;
    try {
      await _player.stop();
    } catch (_) {}
  }

  static bool get isSirenPlaying => _sirenPlaying;
  static int? get activeSosId => _activeSosId;

  // ── LOCATION ──
  static Future<Position?> getCurrentLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (_) {
      return null;
    }
  }

  static String buildMapsLink(Position pos) =>
      'https://maps.google.com/maps?q=${pos.latitude},${pos.longitude}';

  // ── CONTACTS FROM DB ──

  /// Get saved SOS contacts for this user from DB
  static Future<List<Map<String, dynamic>>> getSosContacts(
      String ownerPhone) async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/sos-contacts/$ownerPhone'))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['contacts']);
      }
    } catch (_) {}
    return [];
  }

  /// Save a new SOS contact to DB
  static Future<bool> saveContact({
    required String ownerPhone,
    required String contactName,
    required String contactPhone,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/sos-contacts'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'owner_phone': ownerPhone,
              'contact_name': contactName,
              'contact_phone': contactPhone,
            }),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      return data['success'] == true;
    } catch (e) {
      print('saveContact error: $e');
      return false;
    }
  }

  /// Delete a contact from DB
  static Future<void> deleteContact(int id) async {
    try {
      await http
          .delete(Uri.parse('$_baseUrl/sos-contacts/$id'))
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  /// Get the configured SOS partner for this user
  static Future<Map<String, dynamic>?> getPartnerInfo(String ownerPhone) async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/sos-partners/$ownerPhone'))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return data['partner'] != null
            ? Map<String, dynamic>.from(data['partner'])
            : null;
      }
    } catch (_) {}
    return null;
  }

  /// Save or update the SOS partner mapping for this user
  static Future<bool> savePartner({
    required String ownerPhone,
    required String partnerPhone,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/sos-partners'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'owner_phone': ownerPhone,
              'partner_phone': partnerPhone,
            }),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      return data['success'] == true;
    } catch (e) {
      print('savePartner error: $e');
      return false;
    }
  }

  /// Get an incoming partner alert for this user
  static Future<Map<String, dynamic>?> getIncomingPartnerAlert(
      String ownerPhone) async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/sos-partner-alerts/$ownerPhone'))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return data['alert'] != null
            ? Map<String, dynamic>.from(data['alert'])
            : null;
      }
    } catch (_) {}
    return null;
  }

  /// Stop a partner alert once acknowledged
  static Future<void> stopPartnerAlert(int id) async {
    try {
      await http.put(Uri.parse('$_baseUrl/sos-partner-alerts/stop/$id'),
          headers: {
            'Content-Type': 'application/json'
          }).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  /// Dial a phone number using the device dialer
  static Future<void> dialPhone(String phone) async {
    try {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  // ── SAVE SOS TRIGGER TO DB ──
  static Future<void> saveSosToDb({
    required String fullName,
    required String phoneNumber,
    required String apartment,
    double? latitude,
    double? longitude,
    String? mapsLink,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/sos/trigger'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'full_name': fullName,
              'phone_number': phoneNumber,
              'apartment': apartment,
              'latitude': latitude,
              'longitude': longitude,
              'maps_link': mapsLink ?? '',
            }),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _activeSosId = data['sos']['id'];
      }
    } catch (_) {}
  }

  // ── STOP SOS IN DB ──
  static Future<void> stopSosInDb() async {
    if (_activeSosId == null) return;
    try {
      await http.put(
        Uri.parse('$_baseUrl/sos/stop/$_activeSosId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      _activeSosId = null;
    } catch (_) {}
  }

  // ── GET ACTIVE SOS ALERTS (for other app users) ──
  static Future<List<Map<String, dynamic>>> getActiveSosAlerts() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/sos/active'))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['alerts']);
      }
    } catch (_) {}
    return [];
  }

  // ── SEND WHATSAPP TO ALL SAVED CONTACTS ──
  /// Sends WhatsApp message with location to every contact saved in DB
  static Future<void> sendWhatsAppToContacts(
      List<Map<String, dynamic>> contacts, String mapsLink) async {
    final msg = Uri.encodeComponent(
        '🚨 EMERGENCY ALERT!\n\nI need help urgently.\n\n📍 My live location:\n$mapsLink\n\nPlease respond immediately!');

    for (final contact in contacts) {
      final phone = contact['contact_phone'].toString();
      final waNumber = phone.startsWith('+') ? phone : '+91$phone';
      final uri = Uri.parse('https://wa.me/$waNumber?text=$msg');
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        await Future.delayed(const Duration(seconds: 2));
      } catch (_) {}
    }
  }

  // ── SEND SMS TO ALL SAVED CONTACTS ──
  static Future<void> sendSmsToContacts(
      List<Map<String, dynamic>> contacts, String mapsLink) async {
    final msg = Uri.encodeComponent(
        '🚨 EMERGENCY! I need help. My location: $mapsLink');
    for (final contact in contacts) {
      final phone = contact['contact_phone'].toString();
      final uri = Uri.parse('sms:$phone?body=$msg');
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        await Future.delayed(const Duration(seconds: 2));
      } catch (_) {}
    }
  }

  // ── CALL first contact ──
  static Future<void> callContact(List<Map<String, dynamic>> contacts) async {
    if (contacts.isEmpty) return;
    final phone = contacts[0]['contact_phone'].toString();
    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // ── Open Maps ──
  static Future<void> openMapsLink(String link) async {
    try {
      await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // ── NATIVE CALL DETECTION INTEGRATION ──

  /// Set partner number in native shared preferences
  static Future<bool> setNativePartnerNumber(String phoneNumber) async {
    try {
      const platform = MethodChannel(_nativeChannel);
      final result = await platform.invokeMethod('setPartnerNumber', {
        'phoneNumber': phoneNumber,
      });
      return result == 'Partner number set';
    } catch (e) {
      print('setNativePartnerNumber error: $e');
      return false;
    }
  }

  /// Get partner number from native shared preferences
  static Future<String?> getNativePartnerNumber() async {
    try {
      const platform = MethodChannel(_nativeChannel);
      final result = await platform.invokeMethod('getPartnerNumber');
      return result as String?;
    } catch (e) {
      print('getNativePartnerNumber error: $e');
      return null;
    }
  }

  /// Check if there's a pending native SOS trigger
  static Future<bool> checkNativeSosTrigger() async {
    try {
      const platform = MethodChannel(_nativeChannel);
      final result = await platform.invokeMethod('getPartnerNumber');
      // For now, we'll check shared preferences as a fallback
      final prefs = await SharedPreferences.getInstance();
      final triggered = prefs.getBool('native_sos_trigger') ?? false;
      final triggerTime = prefs.getInt('sos_trigger_time') ?? 0;

      // Only consider recent triggers (within last 30 seconds)
      if (triggered &&
          (DateTime.now().millisecondsSinceEpoch - triggerTime) < 30000) {
        // Clear the trigger
        await prefs.setBool('native_sos_trigger', false);
        return true;
      }
      return false;
    } catch (e) {
      print('checkNativeSosTrigger error: $e');
      return false;
    }
  }

  /// Trigger SOS from native side
  static Future<bool> triggerSosFromNative() async {
    try {
      const platform = MethodChannel(_nativeChannel);
      final result = await platform.invokeMethod('triggerSosFromNative');
      return result == 'SOS triggered';
    } catch (e) {
      print('triggerSosFromNative error: $e');
      return false;
    }
  }
}
