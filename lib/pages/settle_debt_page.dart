// lib/pages/settle_debt_page.dart
import 'package:flutter/material.dart';
import '../models/debt.dart';
import '../services/debt_service.dart';

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
      appBar: AppBar(title: const Text('Settle Debt')),
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
              itemBuilder: (_, i) {
                final d = debts[i];
                return Card(
                  color: d.iOwe ? Colors.red[50] : Colors.green[50],
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(d.title),
                    subtitle: Text('\$${d.amount.toStringAsFixed(2)}'),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        await _service.settleDebt(d.id);
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Settled "${d.title}"!')),
                        );
                        _refresh();
                      },
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
