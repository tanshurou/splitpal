import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity.dart';

class ActivityTile extends StatelessWidget {
  final Activity activity;

  const ActivityTile({super.key, required this.activity});

  Future<String> fetchUserName(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data()?['fullName'] ?? userId;
  }

  Future<String> fetchGroupName(String groupId) async {
    final groupDoc =
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .get();
    return groupDoc.data()?['groupName'] ?? groupId;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder(
      future: Future.wait([
        fetchUserName(activity.userId),
        fetchGroupName(activity.group),
      ]),
      builder: (context, AsyncSnapshot<List<String>> snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(
            leading: CircleAvatar(),
            title: Text('Loading...'),
          );
        }

        final username = snapshot.data![0];
        final groupName = snapshot.data![1];
        final isCurrentUser = activity.userId == currentUserId;
        final name = isCurrentUser ? 'You' : username;

        // Icon and color based on action
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

        String description;
        switch (activity.action) {
          case 'owes':
            description =
                '$name owe RM${activity.amount.toStringAsFixed(2)} in $groupName';
            break;
          case 'paid':
            description =
                '$name paid RM${activity.amount.toStringAsFixed(2)} in $groupName';
            break;
          default:
            description =
                '$name ${activity.action} RM${activity.amount.toStringAsFixed(2)} in $groupName';
        }

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
