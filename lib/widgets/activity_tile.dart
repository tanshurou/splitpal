import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity.dart';

class ActivityTile extends StatelessWidget {
  final Activity activity;

  const ActivityTile({super.key, required this.activity});

  /// Fetch full name based on userId from Firestore
  Future<String> fetchUserName(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data()?['fullName'] ?? userId;
  }

  /// Fetch group name based on groupId from Firestore
  Future<String> fetchGroupName(String groupId) async {
    final groupDoc =
        await FirebaseFirestore.instance.collection('group').doc(groupId).get();
    return groupDoc.data()?['name'] ?? groupId;
  }

  /// Build activity description string based on category
  String buildDescription({
    required String action,
    required String category,
    required String name,
    required String currentUser,
    required double amount,
    required String groupName,
  }) {
    final rm = 'RM${amount.toStringAsFixed(2)}';
    if (category == 'owe') {
      return action == 'paid'
          ? '$currentUser paid $name $rm in $groupName'
          : '$currentUser owe $name $rm in $groupName';
    } else if (category == 'owed') {
      return action == 'paid'
          ? '$name paid you $rm in $groupName'
          : '$name owe you $rm in $groupName';
    } else {
      return '$name $action $rm in $groupName';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<List<String>>(
      future: Future.wait([
        fetchUserName(activity.userId),
        fetchGroupName(activity.group),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(
            leading: CircleAvatar(),
            title: Text('Loading...'),
          );
        }

        final username = snapshot.data![0];
        final groupName = snapshot.data![1];
        final isCurrentUser = activity.userId == currentUserId;
        final currentName = 'You';

        // Set icon and color
        IconData icon;
        Color color;
        switch (activity.action) {
          case 'paid':
            icon = Icons.attach_money;
            color = Colors.green;
            break;
          case 'owes':
            icon = Icons.receipt_long;
            color = Colors.orange;
            break;
          default:
            icon = Icons.info_outline;
            color = Colors.grey;
        }

        final description = buildDescription(
          action: activity.action,
          category: activity.category,
          name: username,
          currentUser: currentName,
          amount: activity.amount,
          groupName: groupName,
        );

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),
          title: Text(description),
          subtitle: Text(DateFormat('MMM dd').format(activity.date)),
        );
      },
    );
  }
}
