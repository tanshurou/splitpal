import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:splitpal/widgets/bottom_nav_bar.dart';
import 'package:splitpal/pages/group_page.dart';
import 'package:splitpal/pages/activity_page.dart';
import 'package:splitpal/pages/personal_dashboard_page.dart';
import 'package:splitpal/pages/settings_page.dart';
import 'package:splitpal/pages/settle_debt_page.dart';
import 'package:splitpal/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    PersonalDashboardPage(userId: FirebaseAuth.instance.currentUser!.uid),
    GroupPage(),
    HistoryPage(),

    SettleDebtPage(),
    const ProfilePage(),
  ];

  void navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex, // ← pass the active tab
        onTabChange: (i) => setState(() => _selectedIndex = i),
      ),
      body: _pages[_selectedIndex],
    );
  }
}
