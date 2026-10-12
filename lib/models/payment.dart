import 'package:flutter/material.dart';

class Bill {
  final String id;
  final String title;
  final String description;
  final double amount;
  final String dueDate;
  final String status; // 'pending', 'paid', 'overdue'
  final String? paidDate;
  final String? transactionId;
  final String? paymentMethod;
  final String
      billType; // 'maintenance', 'community', 'water', 'electricity', 'parking', 'other'
  final String createdBy;
  final DateTime createdAt;
  final List<String> assignedUserIds; // Which users this bill is assigned to

  Bill({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.dueDate,
    this.status = 'pending',
    this.paidDate,
    this.transactionId,
    this.paymentMethod,
    this.billType = 'maintenance',
    required this.createdBy,
    required this.createdAt,
    required this.assignedUserIds,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: json['dueDate'] as String,
      status: json['status'] as String? ?? 'pending',
      paidDate: json['paidDate'] as String?,
      transactionId: json['transactionId'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      billType: json['billType'] as String? ?? 'maintenance',
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      assignedUserIds: List<String>.from(json['assignedUserIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'amount': amount,
        'dueDate': dueDate,
        'status': status,
        'paidDate': paidDate,
        'transactionId': transactionId,
        'paymentMethod': paymentMethod,
        'billType': billType,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'assignedUserIds': assignedUserIds,
      };

  String getBillTypeDisplay() {
    switch (billType) {
      case 'maintenance':
        return 'Maintenance Fee';
      case 'community':
        return 'Community Fund';
      case 'water':
        return 'Water Bill';
      case 'electricity':
        return 'Electricity Bill';
      case 'parking':
        return 'Parking Fee';
      default:
        return billType;
    }
  }

  IconData getBillTypeIcon() {
    switch (billType) {
      case 'maintenance':
        return Icons.build;
      case 'community':
        return Icons.people;
      case 'water':
        return Icons.water_drop;
      case 'electricity':
        return Icons.flash_on;
      case 'parking':
        return Icons.local_parking;
      default:
        return Icons.receipt;
    }
  }

  // Backwards-compatible helper used by UI
  IconData getIcon() => getBillTypeIcon();

  Color getStatusColor() {
    switch (status) {
      case 'paid':
        return const Color(0xFF4CAF50);
      case 'overdue':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFFFF9800);
    }
  }

  String getStatusText() {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'overdue':
        return 'Overdue';
      default:
        return 'Pending';
    }
  }
}

class UserPaymentSummary {
  final String userId;
  final String userName;
  final String apartment;
  final String phone;
  final String email;
  double totalAmount;
  double paidAmount;
  double pendingAmount;
  List<Bill> bills;

  UserPaymentSummary({
    required this.userId,
    required this.userName,
    required this.apartment,
    required this.phone,
    required this.email,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.bills,
  });
}
