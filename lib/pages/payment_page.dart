import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/debt.dart';
import '../models/payment_method.dart';
import '../services/payment_service.dart';

class PaymentPage extends StatefulWidget {
  final Debt debt;

  /// Now expects a Future-returning callback so we can await it
  final Future<void> Function(PaymentMethod) onSelected;

  const PaymentPage({Key? key, required this.debt, required this.onSelected})
    : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Future<List<PaymentMethod>> _methodsFuture;
  int? _selectedIndex;
  bool _isProcessing = false;

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
                Text(
                  'Payment Methods',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: methods.length,
                    itemBuilder: (ctx, i) {
                      final m = methods[i];
                      final sel = _selectedIndex == i;
                      return GestureDetector(
                        onTap:
                            _isProcessing
                                ? null
                                : () => setState(() => _selectedIndex = i),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient:
                                sel
                                    ? const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [gradientStart, gradientEnd],
                                    )
                                    : null,
                            color: sel ? null : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.credit_card,
                                color: sel ? gradientEnd : Colors.black54,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${m.name} ${m.details}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: sel ? gradientEnd : Colors.black87,
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
                  (_selectedIndex != null && !_isProcessing)
                      ? () async {
                        setState(() => _isProcessing = true);
                        await widget.onSelected(methods[_selectedIndex!]);
                        setState(() => _isProcessing = false);
                      }
                      : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: gradientEnd,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child:
                  _isProcessing
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        'Pay',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
            ),
          ),
        );
      },
    );
  }
}
