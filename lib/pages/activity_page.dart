import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitpal/models/activity.dart';
import 'package:splitpal/services/activity_service.dart';
import 'package:splitpal/widgets/activity_tile.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.userId});
  final String userId;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  /// Group activities first by month (e.g., "January"), then by day ("Jan 01 2025")
  Map<String, Map<String, List<Activity>>> groupByMonthThenDay(
    List<Activity> activities,
  ) {
    final Map<String, Map<String, List<Activity>>> grouped = {};

    for (var activity in activities) {
      final date = activity.date;
      final monthKey = DateFormat('MMMM').format(date); // "January"
      final dayKey = DateFormat('MMM dd yyyy').format(date); // "Jan 01 2025"

      grouped.putIfAbsent(monthKey, () => {});
      grouped[monthKey]!.putIfAbsent(dayKey, () => []);
      grouped[monthKey]![dayKey]!.add(activity);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Not signed in'));
    }

    return StreamBuilder<List<Activity>>(
      stream: userActivityStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final activities = snapshot.data ?? [];
        final grouped = groupByMonthThenDay(activities);

        return ListView(
          padding: const EdgeInsets.all(12),
          children:
              grouped.entries.expand((monthEntry) {
                final monthHeader = Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    monthEntry.key,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );

                final days = monthEntry.value.entries.expand((dayEntry) {
                  final dayHeader = Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      dayEntry.key,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );

                  final tiles =
                      dayEntry.value
                          .map((activity) => ActivityTile(activity: activity))
                          .toList();

                  return [dayHeader, ...tiles];
                });

                return [monthHeader, ...days];
              }).toList(),
        );
      },
    );
  }
}
