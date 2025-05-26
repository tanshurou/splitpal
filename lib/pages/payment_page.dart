// lib/pages/payment_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/debt.dart';
import '../pages/banking_details_page.dart'; // for PaymentMethod
import '../services/payment_service.dart'; // import the singleton

class PaymentPage extends StatefulWidget {
  final Debt debt;
  const PaymentPage({Key? key, required this.debt}) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int? _selectedMethodIndex;

  // ← Read from the singleton service
  List<PaymentMethod> get _methods => PaymentService.instance.methods;

  void _onPay() {
    final method = _methods[_selectedMethodIndex!];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Paid \$${widget.debt.amount.toStringAsFixed(2)} via ${method.name} ${method.details}',
        ),
      ),
    );
    Navigator.pop(context, true); // signal success
  }

  @override
  Widget build(BuildContext context) {
    const gradientStart = Color(0xFF7B5FFF);
    const gradientEnd = Color(0xFFFB56A5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settle Debt'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        leading: const BackButton(color: Colors.black87),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.black87),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transfer row
            Row(
              children: [
                const Icon(Icons.swap_horiz, color: Colors.black54),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transfer',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      widget.debt.title,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '\$${widget.debt.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Review placeholder
            Text(
              'Review Transaction',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('Bill Split Detail')),
            ),
            const SizedBox(height: 24),

            // Payment methods list
            Text(
              'Payment Methods',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: _methods.length, // ← from service
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final m = _methods[i]; // ← from service
                  final selected = _selectedMethodIndex == i;
                  return ListTile(
                    tileColor:
                        selected ? Colors.blue.shade50 : Colors.grey.shade200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    leading: Icon(
                      Icons.credit_card,
                      color: selected ? gradientStart : Colors.black54,
                    ),
                    title: Text(
                      '${m.name}  ${m.details}',
                      style: GoogleFonts.poppins(),
                    ),
                    onTap: () => setState(() => _selectedMethodIndex = i),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _selectedMethodIndex != null ? _onPay : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: gradientEnd,
          ),
          child: Text('Pay', style: GoogleFonts.poppins(color: Colors.white)),
        ),
      ),
    );
  }
}
