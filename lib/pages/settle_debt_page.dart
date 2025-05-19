// lib/pages/settle_debt_page.dart
import 'package:flutter/material.dart';
import '../models/debt.dart';
import '../services/debt_service.dart';
import '../widgets/debt_card.dart';
import 'payment_page.dart';

class SettleDebtPage extends StatefulWidget {
  const SettleDebtPage({super.key});

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
    setState(() => _debtsFuture = _service.fetchDebts());
    await _debtsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settle Debt'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
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
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }

          // 1) Compute totals
          final totalOwe = debts
              .where((d) => d.iOwe)
              .fold(0.0, (sum, d) => sum + d.amount);
          final totalDue = debts
              .where((d) => !d.iOwe)
              .fold(0.0, (sum, d) => sum + d.amount);

          // 2) Build header + list of DebtCards
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: debts.length + 1, // +1 for the header
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Summary header
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'You owe \$${totalOwe.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'You’re owed \$${totalDue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final debt = debts[index - 1]; // shift past header
                return DebtCard(
                  debt: debt,
                  onPay: () async {
                    final paid = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentPage(debt: debt),
                      ),
                    );
                    if (paid == true) {
                      // refresh the list immediately
                      setState(() {
                        _debtsFuture = _service.fetchDebts();
                      });
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
