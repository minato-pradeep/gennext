class Event {
  final int id;
  final String title;
  final String description;
  final String dateTime;
  final String postedBy;
  final bool isHallBooking;
  final int bookingId;
  final String hallName;
  final double amount;
  final String paymentStatus;
  // The numeric user-id of whoever booked/created this entry.
  // Populated from `booked_by` (hall bookings) so the UI can show the
  // cancel button to the right person even when the stored name doesn't
  // exactly match the session name.
  final int bookedBy;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.postedBy,
    this.isHallBooking = false,
    this.bookingId = 0,
    this.hallName = '',
    this.amount = 0,
    this.paymentStatus = 'pending',
    this.bookedBy = 0,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final isHallBooking = (json['source'] ?? '').toString() == 'hall_booking';
    final idValue = json['id'] ?? json['source_id'] ?? 0;
    final bookingIdValue = json['booking_id'] ?? json['source_id'] ?? 0;
    final bookedByValue = json['booked_by'] ?? 0;

    return Event(
      id: idValue is int ? idValue : int.tryParse(idValue.toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      dateTime:
          json['date_time']?.toString() ?? json['dateTime']?.toString() ?? '',
      postedBy:
          json['posted_by']?.toString() ?? json['postedBy']?.toString() ?? '',
      isHallBooking: isHallBooking,
      bookingId: bookingIdValue is int
          ? bookingIdValue
          : int.tryParse(bookingIdValue.toString()) ?? 0,
      hallName: json['hall_name']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      bookedBy: bookedByValue is int
          ? bookedByValue
          : int.tryParse(bookedByValue.toString()) ?? 0,
    );
  }
}
