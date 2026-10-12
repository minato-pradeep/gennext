class Visitor {
  final String id;
  final String ownerName;
  final String ownerPhone;
  final String apartmentNo;
  final String visitorName;
  final String visitorPhone;
  final String visitorCount;
  final String checkInTime;
  final String checkOutTime;
  final String status; // 'pending', 'approved', 'rejected', 'checked_out'
  final String date;

  Visitor({
    required this.id,
    required this.ownerName,
    required this.ownerPhone,
    required this.apartmentNo,
    required this.visitorName,
    required this.visitorPhone,
    required this.visitorCount,
    required this.checkInTime,
    required this.checkOutTime,
    required this.status,
    required this.date,
  });
}