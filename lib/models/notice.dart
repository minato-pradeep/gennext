import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Notice {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final String createdByRole;
  final DateTime createdAt;
  final DateTime? expiryDate;
  final String? imageUrl;
  final bool isActive;
  final List<String> tags; // For categories like 'important', 'event', 'announcement'

  Notice({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdByRole,
    required this.createdAt,
    this.expiryDate,
    this.imageUrl,
    this.isActive = true,
    this.tags = const [],
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      createdBy: json['createdBy'] as String,
      createdByRole: json['createdByRole'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate'] as String) : null,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'createdBy': createdBy,
    'createdByRole': createdByRole,
    'createdAt': createdAt.toIso8601String(),
    'expiryDate': expiryDate?.toIso8601String(),
    'imageUrl': imageUrl,
    'isActive': isActive,
    'tags': tags,
  };

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get formattedDateTime {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  Color get priorityColor {
    if (tags.contains('urgent')) return Colors.red;
    if (tags.contains('important')) return Colors.orange;
    if (tags.contains('event')) return Colors.green;
    return AppTheme.primaryBlue;
  }

  IconData get priorityIcon {
    if (tags.contains('urgent')) return Icons.warning;
    if (tags.contains('important')) return Icons.priority_high;
    if (tags.contains('event')) return Icons.event;
    return Icons.announcement;
  }
}