// lib/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex; // ← new
  final ValueChanged<int> onTabChange;
  const BottomNavBar({
    super.key,
    required this.selectedIndex, // ← new
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GNav(
          selectedIndex: selectedIndex, // ← wire it up
          onTabChange: onTabChange, // ← hook back to parent
          color: Colors.grey[300],
          activeColor: Colors.pink[300],
          tabBackgroundColor: Colors.pink.shade50,
          tabBackgroundGradient: LinearGradient(
            colors: [Colors.pink.shade100, Colors.pink.shade50],
          ),
          padding: const EdgeInsets.all(16),
          tabBorderRadius: 20,
          gap: 8,
          tabs: const [
            GButton(icon: Icons.home_filled, text: 'Home'),
            GButton(icon: Icons.group, text: 'Group'),
            GButton(icon: Icons.history_rounded, text: 'History'),
            GButton(icon: Icons.settings_rounded, text: 'Settings'),
            GButton(icon: Icons.attach_money_rounded, text: 'Settle'),
            GButton(icon: Icons.person_outline, text: 'Profile'),
          ],
        ),
      ),
    );
  }
}
