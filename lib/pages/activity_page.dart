import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String selectedFilter = 'All';

  final List<String> filterOptions = [
    'All',
    'You owe',
    'You are owed',
    'Settled',
  ];

  /// Filter logic based on selected option
  List<Activity> applyFilter(List<Activity> activities) {
    switch (selectedFilter) {
      case 'You owe':
        return activities
            .where((a) => a.category == 'owe' && a.action != 'paid')
            .toList();
      case 'You are owed':
        return activities
            .where((a) => a.category == 'owed' && a.action != 'paid')
            .toList();
      case 'Settled':
        return activities.where((a) => a.action == 'paid').toList();
      default:
        return activities;
    }
  }

  /// Group by month → day
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
    if (widget.userId.isEmpty) {
      return const Center(child: Text('Not signed in'));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Removes back button
        titleSpacing: 16,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Activity',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedFilter,
                alignment: AlignmentDirectional.centerStart,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedFilter = value;
                    });
                  }
                },
                items:
                    filterOptions.map((label) {
                      return DropdownMenuItem<String>(
                        value: label,
                        child: Text(
                          label,
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<List<Activity>>(
        stream: userActivityStream(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final rawActivities = snapshot.data ?? [];
          final filteredActivities = applyFilter(rawActivities);
          final grouped = groupByMonthThenDay(filteredActivities);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children:
                grouped.entries.expand((monthEntry) {
                  final monthHeader = Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      monthEntry.key,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  );

                  final days = monthEntry.value.entries.expand((dayEntry) {
                    final dayHeader = Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        dayEntry.key,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
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
      ),
    );
  }
}
