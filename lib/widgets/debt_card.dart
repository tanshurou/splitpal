// lib/widgets/debt_card.dart
import 'package:flutter/material.dart';
import '../models/debt.dart';

class DebtCard extends StatelessWidget {
  final Debt debt;
  final VoidCallback onPay;
  const DebtCard({required this.debt, required this.onPay, super.key});

  @override
  Widget build(BuildContext context) {
    final owesColor = debt.iOwe ? Colors.red.shade100 : Colors.green.shade100;
    final badgeColor = debt.iOwe ? Colors.redAccent : Colors.green;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: owesColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: badgeColor,
            child: Icon(
              debt.iOwe ? Icons.arrow_upward : Icons.arrow_downward,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${debt.amount.toStringAsFixed(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: badgeColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onPay,
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }
}
