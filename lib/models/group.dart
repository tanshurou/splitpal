import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String name;
  final String icon;
  final String createdBy;
  final List<String> members;
  final DateTime? date;

  Group({
    required this.name,
    required this.icon,
    required this.createdBy,
    required this.members,
    this.date,
  });

  factory Group.fromMap(Map<String, dynamic> data) {
    return Group(
      name: data['name'] ?? '',
      icon: data['icon'] ?? '',
      createdBy: data['createdBy'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      date: data['date'] != null ? (data['date'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'createdBy': createdBy,
      'members': members,
      'date': date != null ? Timestamp.fromDate(date!) : null,
    };
  }
}
