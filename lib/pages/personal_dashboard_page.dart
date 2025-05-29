// lib/pages/personal_dashboard_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:splitpal/widgets/summary.dart';
import 'package:splitpal/widgets/activity_tile.dart';
import 'package:splitpal/models/activity.dart';
import 'package:splitpal/services/activity_service.dart';

import 'package:splitpal/pages/settle_debt_page.dart';
import 'package:splitpal/pages/add_expense_page.dart';

class PersonalDashboardPage extends StatefulWidget {
  final String userId;

  const PersonalDashboardPage({super.key, required this.userId});

  @override
  State<PersonalDashboardPage> createState() => _PersonalDashboardPageState();
}

class _PersonalDashboardPageState extends State<PersonalDashboardPage> {
  bool showOwe = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .snapshots(),
      builder: (context, snapshot) {
        // 1) still loading?
        if (snapshot.connectionState != ConnectionState.active) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2) no data or doc doesn’t exist?
        if (!snapshot.hasData ||
            snapshot.data == null ||
            !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('User data not found')),
          );
        }

        // 3) safe to pull the map
        final raw = snapshot.data!.data();
        final data = (raw as Map<String, dynamic>?) ?? {};
        // DEBUG: see exactly what’s coming down
        print('▶ [Dashboard] user data for ${widget.userId}: $data');

        final String username = data['fullName'] as String? ?? 'User';

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(radius: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Welcome back,\n$username',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          if (showOwe) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettleDebtPage(),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AddExpenseStep1Page(
                                      userId:
                                          FirebaseAuth
                                              .instance
                                              .currentUser!
                                              .uid,
                                    ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.pink.shade100,
                                Colors.pink.shade50,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            showOwe ? 'Settle Debt' : 'Add Expenses',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(240, 98, 146, 1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Balance Summary Card
                  UserSummary(userId: widget.userId),
                  const SizedBox(height: 24),

                  const Text('Settle debt', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),

                  // Face icons (placeholder)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      4,
                      (index) => const CircleAvatar(radius: 24),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Owe / Owed Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() => showOwe = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              showOwe ? Colors.pink[100] : Colors.grey[300],
                        ),
                        child: const Text('Owe'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => setState(() => showOwe = false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              !showOwe ? Colors.pink[100] : Colors.white,
                        ),
                        child: const Text('Owed'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // List of filtered activities
                  Expanded(
                    child: StreamBuilder<List<Activity>>(
                      stream: userActivityStream(widget.userId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final filtered =
                            snapshot.data!
                                .where(
                                  (activity) =>
                                      showOwe
                                          ? activity.category == 'owe'
                                          : activity.category == 'owed',
                                )
                                .toList();

                        return ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return ActivityTile(activity: filtered[index]);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
