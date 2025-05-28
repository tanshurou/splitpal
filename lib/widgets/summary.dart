import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class UserSummary extends StatelessWidget {
  final String userId;

  const UserSummary({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('userSummary')
              .doc('S001')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final double owe = (data['owe'] ?? 0).toDouble();
        final double owed = (data['owed'] ?? 0).toDouble();
        final double balance = owed - owe;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side (text)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                child: Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "RM${balance.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text("balance", style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 16),

                        // Owe label
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.pink[300],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Text("Owe", style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        Text(
                          "RM${owe.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Owed label
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 172, 233, 102),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Text("Owed", style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        Text(
                          "RM${owed.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Right side (thinner pie chart)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 30, 15, 8),
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Center(
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            color: Colors.pink[300],
                            value: owe,
                            radius: 35, // thinner ring
                            title: '',
                          ),
                          PieChartSectionData(
                            color: const Color.fromARGB(255, 172, 233, 102),
                            value: owed,
                            radius: 35, // thinner ring
                            title: '',
                          ),
                        ],
                        centerSpaceRadius: 40,
                        sectionsSpace: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
