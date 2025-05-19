// lib/pages/currency_settings_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/currency_service.dart';

class CurrencySettingsPage extends StatefulWidget {
  const CurrencySettingsPage({super.key});

  @override
  State<CurrencySettingsPage> createState() => _CurrencySettingsPageState();
}

class _CurrencySettingsPageState extends State<CurrencySettingsPage> {
  final svc = CurrencyService.instance;
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = svc.current;
  }

  void _onSelect(String code) {
    setState(() => _selected = code);
    svc.current = code;
  }

  @override
  Widget build(BuildContext context) {
    const gradientStart = Color(0xFF7B5FFF);
    const gradientEnd = Color(0xFFFB56A5);
    const bgColor = Color(0xFFF8F8FB);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ─── HEADER ─────────────────────
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
                  'Currency Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ─── CURRENCY LIST ──────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: svc.supported.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final code = svc.supported[i];
                return RadioListTile<String>(
                  value: code,
                  groupValue: _selected,
                  onChanged: (v) => _onSelect(v!),
                  title: Text(code, style: GoogleFonts.poppins(fontSize: 16)),
                  secondary: Text(
                    _currencySymbol(code),
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Simple symbol lookup
  String _currencySymbol(String code) {
    switch (code) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'AUD':
        return 'A\$';
      default:
        return code;
    }
  }
}
