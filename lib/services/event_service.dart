import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event.dart';
import '../utils/constants.dart';

class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  static String get _base => '${AppConstants.baseUrl}/api/events';

  final List<void Function()> _listeners = [];
  void addListener(void Function() l) => _listeners.add(l);
  void removeListener(void Function() l) => _listeners.remove(l);
  void _notify() {
    for (var l in _listeners) {
      l();
    }
  }

  /// Public entry point so other services (e.g. HallBookingService) can
  /// trigger an immediate refresh on all registered screens.
  void notifyListeners() => _notify();

  Future<List<Event>> fetchEvents() async {
    final res =
        await http.get(Uri.parse(_base)).timeout(const Duration(seconds: 10));
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      final events =
          (data['events'] as List).map((e) => Event.fromJson(e)).toList();
      events.sort((a, b) {
        final aDate = parseEventDateTime(a.dateTime);
        final bDate = parseEventDateTime(b.dateTime);
        return bDate.compareTo(aDate);
      });
      return events;
    }
    throw Exception(data['message'] ?? 'Failed to load events');
  }

  DateTime parseEventDateTime(String value) {
    final normalized = _normalizeDateTime(value);
    final match =
        RegExp(r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2}))?')
            .firstMatch(normalized);

    if (match != null) {
      return DateTime(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
        int.parse(match.group(4)!),
        int.parse(match.group(5)!),
        match.group(6) != null ? int.parse(match.group(6)!) : 0,
      );
    }

    return DateTime.parse(normalized);
  }

  String _normalizeDateTime(String value) {
    var normalized = value.trim();
    if (normalized.isEmpty) return normalized;

    normalized = normalized.replaceAll(RegExp(r'\.\d+'), '');

    if (normalized.contains('T')) {
      final tzPattern = RegExp(r'([+-]\d{1,2}:?\d{2}|Z)$');
      final match = tzPattern.firstMatch(normalized);
      if (match != null) {
        normalized = normalized.substring(0, match.start);
      }
    }

    if (normalized.contains('T')) {
      normalized = normalized.replaceFirst('T', ' ');
    }

    return normalized;
  }

  Future<Event> createEvent(
      {required String title,
      required String description,
      required String dateTime,
      required String postedBy}) async {
    final res = await http
        .post(
          Uri.parse(_base),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': title,
            'description': description,
            'date_time': dateTime,
            'posted_by': postedBy
          }),
        )
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      _notify();
      return Event.fromJson(data['event']);
    }
    throw Exception(data['message'] ?? 'Failed to create event');
  }

  Future<void> deleteEvent(Event event) async {
    final targetId = event.isHallBooking ? event.bookingId : event.id;
    final url = event.isHallBooking
        ? Uri.parse('$_base/halls/$targetId')
        : Uri.parse('$_base/$targetId');

    final response =
        await http.delete(url).timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete event');
    }
    _notify();
  }

  // Get next upcoming event from a list
  Event? getNextEvent(List<Event> events) {
    final now = DateTime.now();
    final upcoming = events.where((e) {
      try {
        return parseEventDateTime(e.dateTime).isAfter(now);
      } catch (_) {
        return false;
      }
    }).toList();
    if (upcoming.isNotEmpty) {
      upcoming.sort((a, b) {
        return parseEventDateTime(b.dateTime)
            .compareTo(parseEventDateTime(a.dateTime));
      });
      return upcoming.first;
    }
    return null;
  }
}
