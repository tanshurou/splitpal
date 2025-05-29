import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class GroupDashboardPage extends StatelessWidget {
  final String groupId;

  const GroupDashboardPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final groupRef = FirebaseFirestore.instance.collection('group').doc(groupId);

    return Scaffold(
      appBar: AppBar(title: const Text('Group Dashboard')),
      body: FutureBuilder<DocumentSnapshot>(
        future: groupRef.collection('groupSummary').doc('groupSummary').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Group summary not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final total = data['totalDebts'] ?? 0;
          final settled = data['settleDebts'] ?? 0;
          final unsettled = data['unsettledDebts'] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Debt: RM$total'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: Colors.green,
                          value: settled.toDouble(),
                          title: 'Settled',
                        ),
                        PieChartSectionData(
                          color: Colors.red,
                          value: unsettled.toDouble(),
                          title: 'Unsettled',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: groupRef
                        .collection('activityLog')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Text('No activities.');

                      final logs = snapshot.data!.docs;
                      if (logs.isEmpty) return const Text('No recent activity.');

                      return ListView(
                        children: logs.map((log) {
                          final data = log.data() as Map<String, dynamic>;
                          final message = data.containsKey('message') ? data['message'] : 'No message';
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
