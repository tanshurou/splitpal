import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'group_dashboard_page.dart';
import 'create_group_class_page.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  String _searchQuery = '';

  Future<String?> _getCustomUserId(String email) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty ? snapshot.docs.first.id : null;
  }

  String _getStatusMessage(Map<String, dynamic> summary, String userId) {
    final userOwes = summary['userOwes']?[userId] ?? 0;
    final userOwed = summary['userOwed']?[userId] ?? 0;

    if (userOwes == 0 && userOwed == 0) {
      return "settled up";
    } else if (userOwed > 0) {
      return "you are owed RM${userOwed.toStringAsFixed(2)}";
    } else {
      return "you owe RM${userOwes.toStringAsFixed(2)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return FutureBuilder<String?>(
      future: _getCustomUserId(currentUser.email!),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final userId = userSnapshot.data!;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F3FD),
          appBar: AppBar(
            title: const Text('Your Groups', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFFF4F3FD),
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search group",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('group')
                      .where('members', arrayContains: userId)
                      .orderBy('date', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final filteredGroups = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery);
                    }).toList();

                    if (filteredGroups.isEmpty) {
                      return const Center(
                        child: Text('No groups yet. Tap + to create one.', style: TextStyle(color: Colors.grey)),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredGroups.length,
                      itemBuilder: (context, index) {
                        final doc = filteredGroups[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final groupName = data['name'] ?? 'Unnamed';
                        final groupIcon = data['icon'] ?? '👥';
                        final groupId = doc.id;

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('group')
                              .doc(groupId)
                              .collection('groupSummary')
                              .doc('groupSummary')
                              .get(),
                          builder: (context, summarySnapshot) {
                            String status = "Loading...";
                            if (summarySnapshot.hasData && summarySnapshot.data!.exists) {
                              final summary = summarySnapshot.data!.data() as Map<String, dynamic>;
                              status = _getStatusMessage(summary, userId);
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.purple.shade100,
                                  child: Text(groupIcon, style: const TextStyle(fontSize: 24)),
                                ),
                                title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(status),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => GroupDashboardPage(groupId: groupId)),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFFBCA7FF),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupPage()));
            },
            icon: const Icon(Icons.add),
            label: const Text("Add Group"),
          ),
        );
      },
    );
  }
}
