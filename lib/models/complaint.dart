class Complaint {
  final int id;
  final String userName;
  final String userRole;
  final String userApartment;
  final String issueType;
  final String complaintText;
  final String imageUrl;
  final String status;
  final String dateTime;
  final String? remarks;
  final String? resolvedDate;

  Complaint({
    required this.id,
    required this.userName,
    required this.userRole,
    this.userApartment = '',
    this.issueType = 'Other',
    required this.complaintText,
    this.imageUrl = '',
    this.status = 'pending',
    required this.dateTime,
    this.remarks,
    this.resolvedDate,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userName: json['user_name'] ?? json['userName'] ?? '',
      userRole: json['user_role'] ?? json['userRole'] ?? '',
      userApartment: json['user_apartment'] ?? json['userApartment'] ?? '',
      issueType: json['issue_type'] ?? json['issueType'] ?? 'Other',
      complaintText: json['complaint_text'] ?? json['complaintText'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      status: json['status'] ?? 'pending',
      dateTime: json['created_at']?.toString() ?? json['dateTime'] ?? '',
      remarks: json['remarks'],
      resolvedDate: json['resolved_date']?.toString() ?? json['resolvedDate'],
    );
  }

  Map<String, dynamic> toJson() => {
    'user_name': userName,
    'user_role': userRole,
    'user_apartment': userApartment,
    'issue_type': issueType,
    'complaint_text': complaintText,
    'image_url': imageUrl,
    'status': status,
  };
}
