// lib/pages/payment_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/debt.dart';
import '../models/payment_method.dart';
import '../services/payment_service.dart';

class PaymentPage extends StatefulWidget {
  final Debt debt;
  final void Function(PaymentMethod) onSelected;
  const PaymentPage({Key? key, required this.debt, required this.onSelected})
    : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Future<List<PaymentMethod>> _methodsFuture;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _methodsFuture = PaymentService.instance.fetchMethods();
  }

  @override
  Widget build(BuildContext context) {
    const gradientStart = Color(0xFF7B5FFF);
    const gradientEnd = Color(0xFFFB56A5);
    const bgColor = Color(0xFFF8F8FB);

    return FutureBuilder<List<PaymentMethod>>(
      future: _methodsFuture,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Error loading methods',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
          );
        }

        final methods = snap.data!;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: const BackButton(color: Colors.black),
            title: Text(
              'Settle Debt',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.black),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Transfer + amount row
                Row(
                  children: [
                    const Icon(Icons.swap_horiz, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(
                      'Transfer',
                      style: GoogleFonts.poppins(color: Colors.black54),
                    ),
                    const Spacer(),
                    Text(
                      '\$${widget.debt.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.debt.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 24),

                // Review Transaction box
                Text(
                  'Review Transaction',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'Bill Split Detail',
                      style: GoogleFonts.poppins(color: Colors.black54),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Payment Methods label
                Text(
                  'Payment Methods',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                // Methods list
                Expanded(
                  child: ListView.builder(
                    itemCount: methods.length,
                    itemBuilder: (ctx, i) {
                      final m = methods[i];
                      final selected = _selectedIndex == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIndex = i),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color:
                                selected
                                    ? gradientEnd.withOpacity(0.2)
                                    : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.credit_card,
                                color: selected ? gradientEnd : Colors.black54,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${m.name} ${m.details}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ElevatedButton(
              onPressed:
                  (_selectedIndex != null)
                      ? () {
                        final method = methods[_selectedIndex!];
                        widget.onSelected(method);
                      }
                      : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: gradientEnd,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                'Pay',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        );
      },
    );
  }
}
