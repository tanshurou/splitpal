// lib/pages/settle_debt_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/debt.dart';
import '../services/debt_service.dart';
import '../services/currency_service.dart';
import 'payment_page.dart';

class SettleDebtPage extends StatefulWidget {
  const SettleDebtPage({Key? key}) : super(key: key);

  @override
  State<SettleDebtPage> createState() => _SettleDebtPageState();
}

class _SettleDebtPageState extends State<SettleDebtPage> {
  final _debtSvc = DebtService();
  final _currencySvc = CurrencyService.instance;

  @override
  void initState() {
    super.initState();
    // load the user's currency
    _currencySvc.loadCurrency().then((_) => setState(() {}));
  }

  void _onPay(Debt debt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PaymentPage(
              debt: debt,
              onSelected: (method) async {
                await _debtSvc.settleDebt(debt);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Settled "${debt.title}" via ${method.name}',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                );
                Navigator.pop(context);
                // no manual refresh needed—stream will update automatically
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
      ),
      body: StreamBuilder<List<Debt>>(
        stream: _debtSvc.streamDebts(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final debts = snap.data ?? [];
          if (debts.isEmpty) {
            return const Center(
              child: Text('All caught up!', style: TextStyle(fontSize: 18)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: debts.length,
            itemBuilder: (ctx, i) {
              final d = debts[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: d.iOwe ? Colors.red[50] : Colors.green[50],
                child: ListTile(
                  title: Text(
                    d.title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _currencySvc.symbolFor(d.amount),
                    style: GoogleFonts.poppins(),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _onPay(d),
                    child: const Text('Pay Now'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
