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
              .doc('userSummary')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final double owe = (data['owe'] ?? 0).toDouble();
        final double owed = (data['owed'] ?? 0).toDouble();
        final double balance = owed - owe;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 400;

              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text section
                  Expanded(
                    flex: 2,
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

                          // Owe
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

                          // Owed
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
                              const Text(
                                "Owed",
                                style: TextStyle(fontSize: 14),
                              ),
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

                  // Pie chart section
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24, right: 16),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: PieChart(
                          PieChartData(
                            sections:
                                (owe == 0 && owed == 0)
                                    ? [
                                      PieChartSectionData(
                                        color: const Color.fromARGB(
                                          255,
                                          179,
                                          179,
                                          179,
                                        ),
                                        value: 1,
                                        radius: 30,
                                        title: '',
                                      ),
                                    ]
                                    : [
                                      PieChartSectionData(
                                        color: const Color.fromARGB(
                                          255,
                                          255,
                                          136,
                                          176,
                                        ),
                                        value: owe,
                                        radius: 30,
                                        title: '',
                                      ),
                                      PieChartSectionData(
                                        color: const Color.fromARGB(
                                          255,
                                          214,
                                          248,
                                          129,
                                        ),
                                        value: owed,
                                        radius: 30,
                                        title: '',
                                      ),
                                    ],
                            centerSpaceRadius: 30,
                            sectionsSpace: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
