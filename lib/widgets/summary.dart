import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class UserSummaryWidget extends StatelessWidget {
  final double owe;
  final double owed;

  const UserSummaryWidget({super.key, required this.owe, required this.owed});

  @override
  Widget build(BuildContext context) {
    final double balance = owed - owe;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text section
          Expanded(
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

          // Pie chart section
          SizedBox(
            width: 120,
            height: 120,
            child: PieChart(
              PieChartData(
                sections: _buildPieChartSections(owe, owed),
                centerSpaceRadius: 30,
                sectionsSpace: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(double owe, double owed) {
    if (owe == 0 && owed == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey[400],
          value: 1,
          title: '',
          radius: 30,
        ),
      ];
    }

    return [
      if (owe > 0)
        PieChartSectionData(
          color: const Color.fromARGB(255, 255, 136, 176),
          value: owe,
          title: '',
          radius: 30,
        ),
      if (owed > 0)
        PieChartSectionData(
          color: const Color.fromARGB(255, 214, 248, 129),
          value: owed,
          title: '',
          radius: 30,
        ),
    ];
  }
}
