// lib/pages/notification_settings_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});
  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final svc = NotificationService.instance;

  @override
  Widget build(BuildContext context) {
    const gradientStart = Color(0xFF7B5FFF);
    const gradientEnd = Color(0xFFFB56A5);
    const bgColor = Color(0xFFF8F8FB);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ─── HEADER ─────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 24,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [gradientStart, gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Row(
              children: [
                BackButton(color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Notification Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ─── TOGGLE LIST ────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                SwitchListTile(
                  title: Text('Push Reminders', style: GoogleFonts.poppins()),
                  subtitle: Text(
                    'Get neutral, automated push alerts',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  value: svc.pushReminders,
                  onChanged: (v) => setState(() => svc.setPushReminders(v)),
                  activeColor: gradientEnd, // TL11: friendly accent
                ),
                const Divider(),

                SwitchListTile(
                  title: Text('Email Reminders', style: GoogleFonts.poppins()),
                  subtitle: Text(
                    'Receive impersonal email notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  value: svc.emailReminders,
                  onChanged: (v) => setState(() => svc.setEmailReminders(v)),
                  activeColor: gradientEnd,
                ),
                const Divider(),

                SwitchListTile(
                  title: Text(
                    'Payment Confirmations',
                    style: GoogleFonts.poppins(),
                  ),
                  subtitle: Text(
                    'Confirm transactions with a friendly note',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  value: svc.paymentConfirmations,
                  onChanged:
                      (v) => setState(() => svc.setPaymentConfirmations(v)),
                  activeColor: gradientEnd,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
