import 'package:flutter/material.dart';

class UserPermissions {
  bool emergency;
  bool buySell;
  bool raiseComplaint;
  bool allComplaints;
  bool events;
  bool facilities;
  bool payments;
  bool visitors;
  bool visitorApproval;
  bool polls;
  bool documents;
  bool maintenance;
  bool noticeBoard;
  bool checkComplaint;
  bool profile;

  UserPermissions({
    this.emergency = false,
    this.buySell = false,
    this.raiseComplaint = false,
    this.allComplaints = false,
    this.events = false,
    this.facilities = false,
    this.payments = false,
    this.visitors = false,
    this.visitorApproval = false,
    this.polls = false,
    this.documents = false,
    this.maintenance = false,
    this.noticeBoard = false,
    this.checkComplaint = false,
    this.profile = true,
  });

  // Get all permissions as a map
  Map<String, bool> toMap() {
    return {
      'emergency': emergency,
      'buySell': buySell,
      'raiseComplaint': raiseComplaint,
      'allComplaints': allComplaints,
      'events': events,
      'facilities': facilities,
      'payments': payments,
      'visitors': visitors,
      'visitorApproval': visitorApproval,
      'polls': polls,
      'documents': documents,
      'maintenance': maintenance,
      'noticeBoard': noticeBoard,
      'checkComplaint': checkComplaint,
      'profile': profile,
    };
  }

  factory UserPermissions.fromMap(Map<String, dynamic> map) {
    return UserPermissions(
      emergency: map['emergency'] ?? false,
      buySell: map['buySell'] ?? false,
      raiseComplaint: map['raiseComplaint'] ?? false,
      allComplaints: map['allComplaints'] ?? false,
      events: map['events'] ?? false,
      facilities: map['facilities'] ?? false,
      payments: map['payments'] ?? false,
      visitors: map['visitors'] ?? false,
      visitorApproval: map['visitorApproval'] ?? false,
      polls: map['polls'] ?? false,
      documents: map['documents'] ?? false,
      maintenance: map['maintenance'] ?? false,
      noticeBoard: map['noticeBoard'] ?? false,
      checkComplaint: map['checkComplaint'] ?? false,
      profile: map['profile'] ?? true,
    );
  }

  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    return UserPermissions.fromMap(json);
  }

  Map<String, dynamic> toJson() => toMap();

  // Get list of enabled permission keys
  List<String> getEnabledPermissions() {
    return toMap().entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
  }

  // Set all permissions to true (for App Master)
  void enableAll() {
    emergency = true;
    buySell = true;
    raiseComplaint = true;
    allComplaints = true;
    events = true;
    facilities = true;
    payments = true;
    visitors = true;
    visitorApproval = true;
    polls = true;
    documents = true;
    maintenance = true;
    noticeBoard = true;
    checkComplaint = true;
    profile = true;
  }

  // Copy with changes
  UserPermissions copyWith({
    bool? emergency,
    bool? buySell,
    bool? raiseComplaint,
    bool? allComplaints,
    bool? events,
    bool? facilities,
    bool? payments,
    bool? visitors,
    bool? visitorApproval,
    bool? polls,
    bool? documents,
    bool? maintenance,
    bool? noticeBoard,
    bool? checkComplaint,
    bool? profile,
  }) {
    return UserPermissions(
      emergency: emergency ?? this.emergency,
      buySell: buySell ?? this.buySell,
      raiseComplaint: raiseComplaint ?? this.raiseComplaint,
      allComplaints: allComplaints ?? this.allComplaints,
      events: events ?? this.events,
      facilities: facilities ?? this.facilities,
      payments: payments ?? this.payments,
      visitors: visitors ?? this.visitors,
      visitorApproval: visitorApproval ?? this.visitorApproval,
      polls: polls ?? this.polls,
      documents: documents ?? this.documents,
      maintenance: maintenance ?? this.maintenance,
      noticeBoard: noticeBoard ?? this.noticeBoard,
      checkComplaint: checkComplaint ?? this.checkComplaint,
      profile: profile ?? this.profile,
    );
  }
}

// List of all available options for display in permission screen
class ExploreOptionItem {
  final String id;
  final String title;
  final IconData icon;
  final String description;
  final String permissionKey;

  ExploreOptionItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.permissionKey,
  });

  static List<ExploreOptionItem> getAllOptions() {
    return [
      ExploreOptionItem(
        id: '1',
        title: 'Emergency',
        icon: Icons.emergency,
        description: 'Quick access to emergency contacts',
        permissionKey: 'emergency',
      ),
      ExploreOptionItem(
        id: '2',
        title: 'Buy & Sell',
        icon: Icons.storefront,
        description: 'Sell or buy items within community',
        permissionKey: 'buySell',
      ),
      ExploreOptionItem(
        id: '3',
        title: 'Raise Complaint',
        icon: Icons.report_problem,
        description: 'Report an issue or concern',
        permissionKey: 'raiseComplaint',
      ),
      ExploreOptionItem(
        id: '4',
        title: 'All Complaints',
        icon: Icons.list_alt,
        description: 'View all complaints with status',
        permissionKey: 'allComplaints',
      ),
      ExploreOptionItem(
        id: '5',
        title: 'Events',
        icon: Icons.event,
        description: 'Create and view community events',
        permissionKey: 'events',
      ),
      ExploreOptionItem(
        id: '6',
        title: 'Facilities',
        icon: Icons.fitness_center,
        description: 'Book community facilities',
        permissionKey: 'facilities',
      ),
      ExploreOptionItem(
        id: '7',
        title: 'Payments',
        icon: Icons.payments,
        description: 'Maintenance and dues payment',
        permissionKey: 'payments',
      ),
      ExploreOptionItem(
        id: '8',
        title: 'Visitors',
        icon: Icons.people,
        description: 'Register visitors for your apartment',
        permissionKey: 'visitors',
      ),
      ExploreOptionItem(
        id: '9',
        title: 'Visitor Approval',
        icon: Icons.security,
        description: 'Security: Approve visitor entries',
        permissionKey: 'visitorApproval',
      ),
      ExploreOptionItem(
        id: '10',
        title: 'Polls',
        icon: Icons.poll,
        description: 'Community voting and polls',
        permissionKey: 'polls',
      ),
      ExploreOptionItem(
        id: '11',
        title: 'Documents',
        icon: Icons.folder,
        description: 'Important community documents',
        permissionKey: 'documents',
      ),
      ExploreOptionItem(
        id: '12',
        title: 'Maintenance',
        icon: Icons.build,
        description: 'Request maintenance service',
        permissionKey: 'maintenance',
      ),
      ExploreOptionItem(
        id: '13',
        title: 'Notice Board',
        icon: Icons.announcement,
        description: 'View official announcements',
        permissionKey: 'noticeBoard',
      ),
      ExploreOptionItem(
        id: '14',
        title: 'Check Complaint',
        icon: Icons.assignment_turned_in,
        description: 'Update complaint status',
        permissionKey: 'checkComplaint',
      ),
    ];
  }
}