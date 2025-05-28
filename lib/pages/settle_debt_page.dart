// lib/pages/settle_debt_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/debt.dart';
import '../services/debt_service.dart';
import '../models/payment_method.dart';
import 'payment_page.dart';

class SettleDebtPage extends StatefulWidget {
  const SettleDebtPage({Key? key}) : super(key: key);

  @override
  State<SettleDebtPage> createState() => _SettleDebtPageState();
}

class _SettleDebtPageState extends State<SettleDebtPage> {
  final _service = DebtService();
  late Future<List<Debt>> _debtsFuture;

  @override
  void initState() {
    super.initState();
    _debtsFuture = _service.fetchDebts();
  }

  Future<void> _refresh() async {
    // do the work first
    final next = _service.fetchDebts();
    // then update state synchronously
    setState(() {
      _debtsFuture = next;
    });
    // now await so pull-to-refresh spinner works
    await next;
  }

  void _goToPayment(Debt d) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PaymentPage(
              debt: d,
              onSelected: (method) async {
                await _service.settleDebt(d.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Settled "${d.title}" with ${method.name}',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                );
                Navigator.pop(context); // back from PaymentPage
                _refresh(); // reload debts
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settle Debt'),
        leading: const BackButton(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Debt>>(
        future: _debtsFuture,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final debts = snap.data ?? [];
          if (debts.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Text(
                      'No debts to settle',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: debts.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (ctx, i) {
                final d = debts[i];
                return Card(
                  color: d.iOwe ? Colors.red[50] : Colors.green[50],
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(
                      d.title,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '\$${d.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _goToPayment(d),
                      child: const Text('Pay Now'),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
