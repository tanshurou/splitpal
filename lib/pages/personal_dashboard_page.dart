import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:splitpal/services/getUserID.dart';
import 'package:splitpal/widgets/summary.dart';
import 'package:splitpal/widgets/activity_tile.dart';
import 'package:splitpal/models/activity.dart';
import 'package:splitpal/services/activity_service.dart';
import 'package:splitpal/pages/settle_debt_page.dart';
import 'package:splitpal/pages/add_expense_page.dart';

class PersonalDashboardPage extends StatefulWidget {
  const PersonalDashboardPage({super.key});

  @override
  State<PersonalDashboardPage> createState() => _PersonalDashboardPageState();
}

class _PersonalDashboardPageState extends State<PersonalDashboardPage> {
  bool showOwe = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _resolveUserId();
  }

  Future<void> _resolveUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final resolvedId = await getUserIdByEmail(user.email!);
      if (mounted) {
        setState(() => userId = resolvedId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final raw = snapshot.data!.data();
        final data = (raw as Map<String, dynamic>?) ?? {};
        final String username = data['fullName'] as String? ?? 'User';

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
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
                                    (context) =>
                                        AddExpenseStep1Page(userId: userId!),
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

                  // Pie Chart Summary with shadow
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: UserSummary(userId: userId!),
                  ),

                  const SizedBox(height: 24),

                  // Owe / Owed Toggle with contrast + animation + shadow
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F8), // very light pink
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => showOwe = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient:
                                    showOwe
                                        ? LinearGradient(
                                          colors: [
                                            Colors.pink.shade100,
                                            Colors.pink.shade50,
                                          ],
                                        )
                                        : null,
                                color: showOwe ? null : Colors.transparent,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Owe',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      showOwe
                                          ? Colors.pink[400]
                                          : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => showOwe = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient:
                                    !showOwe
                                        ? LinearGradient(
                                          colors: [
                                            Colors.pink.shade100,
                                            Colors.pink.shade50,
                                          ],
                                        )
                                        : null,
                                color: !showOwe ? null : Colors.transparent,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Owed',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      !showOwe
                                          ? Colors.pink[400]
                                          : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Activity list
                  Expanded(
                    child: StreamBuilder<List<Activity>>(
                      stream: userActivityStream(userId!),
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

                        if (filtered.isEmpty) {
                          return const Center(
                            child: Text('No activities to show'),
                          );
                        }

                        return ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder:
                              (context, index) =>
                                  ActivityTile(activity: filtered[index]),
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
