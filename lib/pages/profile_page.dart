// lib/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitpal/pages/add_friend_page.dart';
import 'package:splitpal/pages/banking_details_page.dart';
import '../pages/currency_settings_page.dart'; // add this import
import 'package:splitpal/pages/notification_settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Theme colors
    const bgColor = Color(0xFFF8F8FB);
    const gradientStart = Color(0xFF7B5FFF);
    const gradientEnd = Color(0xFFFB56A5);
    const tileBg = Colors.white;
    const iconColor = Color(0xFF7B5FFF);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ─── HEADER ─────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [gradientStart, gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white24,
                  child: const Icon(
                    Icons.person,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Username',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ─── MENU ───────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ListView(
                children: [
                  _ProfileTile(
                    icon: Icons.person_outline,
                    label: 'Manage Account',
                    iconColor: iconColor,
                    onTap: () {
                      /* TODO */
                    },
                  ),
                  const SizedBox(height: 12),
                  _ProfileTile(
                    icon: Icons.person_add_alt_outlined,
                    label: 'Add a Friend',
                    iconColor: iconColor,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddFriendPage(),
                          ),
                        ),
                  ),
                  const SizedBox(height: 12),
                  _ProfileTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notification Settings',
                    iconColor: iconColor,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationSettingsPage(),
                          ),
                        ),
                  ),
                  const SizedBox(height: 12),
                  _ProfileTile(
                    icon: Icons.attach_money_outlined,
                    label: 'Currency Settings',
                    iconColor: iconColor,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CurrencySettingsPage(),
                          ),
                        ),
                  ),
                  const SizedBox(height: 12),
                  _ProfileTile(
                    icon: Icons.account_balance,
                    label: 'Banking Details',
                    iconColor: iconColor,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BankingDetailsPage(),
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor, size: 28),
        title: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.black26),
      ),
    );
  }
}
