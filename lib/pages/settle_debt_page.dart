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
  _SettleDebtPageState createState() => _SettleDebtPageState();
}

class _SettleDebtPageState extends State<SettleDebtPage> {
  final _service = DebtService();
  final _currencySvc = CurrencyService.instance;
  late Future<List<Debt>> _debtsFuture;

  @override
  void initState() {
    super.initState();
    // load user’s currency preference first
    _currencySvc.loadCurrency().then((_) {
      setState(() {}); // force a rebuild to pick up new symbol/rate
    });
    _debtsFuture = _service.fetchDebts();
  }

  Future<void> _refresh() async {
    final next = _service.fetchDebts();
    setState(() => _debtsFuture = next);
    await next;
  }

  void _onPay(Debt debt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PaymentPage(
              debt: debt,
              onSelected: (method) async {
                await _service.settleDebt(debt);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Settled "${debt.title}" via ${method.name}',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                );
                Navigator.pop(context);
                await _refresh();
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
      body: FutureBuilder<List<Debt>>(
        future: _debtsFuture,
        builder: (ctx, snapshot) {
          // Loading
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          // Error
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final debts = snapshot.data ?? [];
          // Empty
          if (debts.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Text(
                      'All caught up!',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            );
          }
          // List
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: debts.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (ctx, i) {
                final d = debts[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: d.iOwe ? Colors.red[50] : Colors.green[50],
                  child: ListTile(
                    title: Text(
                      d.title,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      // ← show converted amount
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
            ),
          );
        },
      ),
    );
  }
}
