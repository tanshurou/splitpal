import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GroupDashboardPage extends StatelessWidget {
  final String groupId;

  const GroupDashboardPage({super.key, required this.groupId});

  Future<void> leaveGroup(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Get user's custom UID like "U001"
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: currentUser.email)
        .get();
    if (userSnapshot.docs.isEmpty) return;
    final userId = userSnapshot.docs.first.id;

    final groupRef = FirebaseFirestore.instance.collection('group').doc(groupId);
    await groupRef.update({
      'members': FieldValue.arrayRemove([userId])
    });

    Navigator.pop(context); // go back to Group Page
  }

  Future<void> addMembers(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final groupRef = FirebaseFirestore.instance.collection('group').doc(groupId);
    final groupSnapshot = await groupRef.get();
    final groupData = groupSnapshot.data() as Map<String, dynamic>;
    final existingMembers = List<String>.from(groupData['members'] ?? []);

    final userSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final allUsers = userSnapshot.docs;

    final newMembers = <String>{};
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Members'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: allUsers.map((doc) {
                final userId = doc.id;
                final name = doc['fullName'] ?? 'Unknown';
                final alreadyInGroup = existingMembers.contains(userId);
                return CheckboxListTile(
                  title: Text(name),
                  value: newMembers.contains(userId),
                  onChanged: alreadyInGroup
                      ? null
                      : (checked) {
                          if (checked == true) {
                            newMembers.add(userId);
                          } else {
                            newMembers.remove(userId);
                          }
                        },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await groupRef.update({
                  'members': FieldValue.arrayUnion(newMembers.toList())
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupRef = FirebaseFirestore.instance.collection('group').doc(groupId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Members',
            onPressed: () => addMembers(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Leave Group',
            onPressed: () => leaveGroup(context),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F3FD),
      body: FutureBuilder<DocumentSnapshot>(
        future: groupRef.get(),
        builder: (context, groupSnapshot) {
          if (!groupSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final groupData = groupSnapshot.data!.data() as Map<String, dynamic>;
          final groupName = groupData['name'] ?? 'Unnamed';
          final members = groupData['members'] as List<dynamic>? ?? [];
          final memberCount = members.length;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text('$memberCount members', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),

                // Group Summary
                FutureBuilder<DocumentSnapshot>(
                  future: groupRef.collection('groupSummary').doc('groupSummary').get(),
                  builder: (context, summarySnapshot) {
                    if (!summarySnapshot.hasData || !summarySnapshot.data!.exists) {
                      return const SizedBox();
                    }

                    final data = summarySnapshot.data!.data() as Map<String, dynamic>;
                    final settled = data['settleDebts'] ?? 0;
                    final unsettled = data['unsettledDebts'] ?? 0;
                    final total = settled + unsettled;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RM$total unpaid debt', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 180,
                          child: PieChart(
                            PieChartData(
                              centerSpaceRadius: 50,
                              sections: [
                                PieChartSectionData(
                                  color: Colors.green,
                                  value: settled.toDouble(),
                                  title: 'Settled',
                                  radius: 50,
                                  titleStyle: const TextStyle(fontSize: 14, color: Colors.white),
                                ),
                                PieChartSectionData(
                                  color: Colors.red,
                                  value: unsettled.toDouble(),
                                  title: 'Unsettled',
                                  radius: 50,
                                  titleStyle: const TextStyle(fontSize: 14, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),

                const Text(
                  'Pending',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: groupRef
                        .collection('activityLog')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Loading...');
                      }
                      if (snapshot.hasError) {
                        return const Text('Error loading activity.');
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Text('No recent activity.');
                      }

                      return ListView(
                        children: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final message = data['message'] ?? 'No message';
                          return ListTile(title: Text(message));
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
