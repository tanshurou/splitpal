// lib/models/debt.dart
class Debt {
  final String id;
  final String title; // e.g. “Dinner w/ Bob”
  final double amount;
  final bool iOwe; // true = you owe them; false = they owe you

  Debt({
    required this.id,
    required this.title,
    required this.amount,
    required this.iOwe,
  });
}
