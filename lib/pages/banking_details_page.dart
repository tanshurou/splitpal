// lib/pages/banking_details_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/payment_service.dart';

/// Top‐level model class
class PaymentMethod {
  String name;
  String details;
  PaymentMethod({required this.name, required this.details});
}

class BankingDetailsPage extends StatefulWidget {
  const BankingDetailsPage({super.key});
  @override
  State<BankingDetailsPage> createState() => _BankingDetailsPageState();
}

class _BankingDetailsPageState extends State<BankingDetailsPage> {
  final svc = PaymentService.instance;

  void _deleteMethod(int idx) {
    setState(() => svc.deleteMethodAt(idx));
  }

  Future<void> _addMethodDialog() async {
    String? name, details;
    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Add Payment Method', style: GoogleFonts.poppins()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Name (e.g. Visa)'),
                  onChanged: (v) => name = v,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Details (**** 1234)'),
                  onChanged: (v) => details = v,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () {
                  if (name != null && name!.trim().isNotEmpty) {
                    // ← Use the service, not a local _methods list
                    svc.addMethod(
                      PaymentMethod(
                        name: name!.trim(),
                        details: details?.trim() ?? '',
                      ),
                    );
                    setState(() {}); // rebuild to show new entry
                  }
                  Navigator.pop(ctx);
                },
                child: Text('Add', style: GoogleFonts.poppins()),
              ),
            ],
          ),
    );
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
          // HEADER
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
                  'Banking Details',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // LIST OF METHODS
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: svc.methods.length, // ← replaced _methods.length
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final m = svc.methods[i]; // ← replaced _methods[i]
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.credit_card, color: gradientStart),
                    title: Text(
                      m.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(m.details, style: GoogleFonts.poppins()),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _deleteMethod(i),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // ADD BUTTON
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMethodDialog,
        backgroundColor: gradientEnd,
        label: Text('Add Method', style: GoogleFonts.poppins()),
        icon: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
