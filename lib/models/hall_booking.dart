class HallBooking {
  final int id;
  final String hallName;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final double amount;
  final String eventTitle;
  // Numeric user-id of the person who created this booking.
  // Used so the UI can show the cancel button only to the owner.
  final int bookedBy;

  HallBooking({
    required this.id,
    required this.hallName,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.amount,
    required this.eventTitle,
    this.bookedBy = 0,
  });

  factory HallBooking.fromJson(Map<String, dynamic> json) => HallBooking(
        id: int.parse(json['id'].toString()),
        hallName: json['hall_name'].toString(),
        bookingDate: json['booking_date'].toString(),
        startTime: json['start_time'].toString().substring(0, 5),
        endTime: json['end_time'].toString().substring(0, 5),
        amount: double.tryParse(json['amount'].toString()) ?? 0,
        eventTitle: json['event_title'].toString(),
        bookedBy: int.tryParse(json['booked_by']?.toString() ?? '') ?? 0,
      );
}
