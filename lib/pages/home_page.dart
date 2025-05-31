import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:splitpal/pages/group_page.dart';
import 'package:splitpal/services/getUserID.dart';
import 'package:splitpal/widgets/bottom_nav_bar.dart';
import 'package:splitpal/pages/activity_page.dart';
import 'package:splitpal/pages/personal_dashboard_page.dart';
import 'package:splitpal/pages/settle_debt_page.dart';
import 'package:splitpal/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email;

    if (email == null) {
      return const Scaffold(body: Center(child: Text("Not signed in")));
    }

    return FutureBuilder<String?>(
      future: getUserIdByEmail(email),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userId = snapshot.data!;

        final pages = [
          PersonalDashboardPage(),
          GroupPage(),
          HistoryPage(userId: userId),
          const ProfilePage(),
        ];

        return Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar: BottomNavBar(
            selectedIndex: _selectedIndex,
            onTabChange: (i) => setState(() => _selectedIndex = i),
          ),
          body: pages[_selectedIndex],
        );
      },
    );
  }
}
