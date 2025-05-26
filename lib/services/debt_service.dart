// lib/services/debt_service.dart
import 'dart:async';
import '../models/debt.dart';

class DebtService {
  static final _mockDebts = <Debt>[
    Debt(id: '1', title: 'Dinner w/ Bob', amount: 24.50, iOwe: true),
    Debt(id: '2', title: 'Coffee from Alice', amount: 5.00, iOwe: false),
  ];

  Future<List<Debt>> fetchDebts() async {
    await Future.delayed(Duration(milliseconds: 300));
    return List.of(_mockDebts);
  }

  Future<void> settleDebt(String debtId) async {
    await Future.delayed(Duration(milliseconds: 300));
    _mockDebts.removeWhere((d) => d.id == debtId);
  }
}
