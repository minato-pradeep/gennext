import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hall_booking.dart';
import '../services/event_service.dart';
import '../utils/constants.dart';

class HallBookingService {
  static String get _base => '${AppConstants.baseUrl}/api/events/halls';

  Future<List<HallBooking>> fetchBookings() async {
    final response = await http.get(Uri.parse('$_base/bookings'));
    final data = jsonDecode(response.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load bookings');
    }
    return (data['bookings'] as List)
        .map((item) => HallBooking.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> bookHall({
    required String hallName,
    required String bookedByName,
    required int bookedBy,
    required DateTime date,
    required TimeOfDayValue start,
    required TimeOfDayValue end,
    required String eventTitle,
    required String description,
    required double amount,
    required List<int> invitedUserIds,
    String paymentStatus = 'pending',
  }) async {
    final response = await http.post(
      Uri.parse('$_base/book'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'hall_name': hallName,
        'booked_by': bookedBy,
        'booked_by_name': bookedByName,
        'booking_date':
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'start_time': start.value,
        'end_time': end.value,
        'event_title': eventTitle,
        'event_description': description,
        'amount': amount,
        'payment_status': paymentStatus,
        'invited_user_ids': invitedUserIds,
      }),
    );
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw Exception(
          'Booking API returned HTTP ${response.statusCode}, not JSON. Check that the backend server is running at ${AppConstants.baseUrl}.');
    }
    final data = jsonDecode(response.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Hall booking failed');
    }
    // Notify all EventService listeners so the dashboard and events list
    // refresh immediately without waiting for the next poll cycle.
    EventService().notifyListeners();
  }

  /// Cancels (deletes) a hall booking by its id.
  Future<void> cancelBooking(int bookingId) async {
    final response =
        await http.delete(Uri.parse('$_base/$bookingId'));
    final data = jsonDecode(response.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to cancel booking');
    }
  }
}

class TimeOfDayValue {
  final int hour;
  final int minute;
  const TimeOfDayValue(this.hour, this.minute);

  String get value =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
