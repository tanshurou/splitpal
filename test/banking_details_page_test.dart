// test/banking_details_page_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitpal/models/payment_method.dart';
import 'package:splitpal/pages/banking_details_page.dart';
import 'package:splitpal/services/payment_service.dart';

/// A simple in‐memory fake implementation of PaymentService.
/// It starts with an empty list and lets us add/delete entries.
class FakePaymentService implements PaymentService {
  final List<PaymentMethod> _storage = [];

  FakePaymentService._create();
  static final FakePaymentService instance = FakePaymentService._create();

  @override
  Future<List<PaymentMethod>> fetchMethods() async {
    return List<PaymentMethod>.from(_storage);
  }

  @override
  Future<void> addMethod(String name, String rawNumber) async {
    final digits = rawNumber.replaceAll(RegExp(r'\D'), '');
    final suffix =
        digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
    final masked = '**** $suffix';
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _storage.add(PaymentMethod(id: id, name: name, details: masked));
  }

  @override
  Future<void> deleteMethod(String id) async {
    _storage.removeWhere((m) => m.id == id);
  }
}

void main() {
  testWidgets(
    'TC-PM-01: Add Payment Method → appears in list & can be deleted',
    (tester) async {
      // 1. Use our fake service that starts empty
      final fakeSvc = FakePaymentService.instance;

      // 2. Pump BankingDetailsPage, injecting fakeSvc as serviceOverride.
      await tester.pumpWidget(
        MaterialApp(home: BankingDetailsPage(serviceOverride: fakeSvc)),
      );
      // Let the initial FutureBuilder finish
      await tester.pumpAndSettle();

      // 3. Verify empty state message is shown
      expect(find.text('No payment methods yet'), findsOneWidget);

      // 4. Tap the "Add Method" button
      await tester.tap(find.text('Add Method'));
      await tester.pumpAndSettle();

      // 5. Enter "Visa" for name and "4111111111111111" for card number
      await tester.enterText(find.byType(TextField).at(0), 'Visa');
      await tester.enterText(find.byType(TextField).at(1), '4111111111111111');

      // 6. Tap "Add" in the dialog
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // 7. Verify the new card appears with masked details
      expect(find.text('Visa'), findsOneWidget);
      expect(find.text('**** 1111'), findsOneWidget);

      // 8. Tap the delete icon to remove that card
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // 9. Confirm the list is empty again
      expect(find.text('Visa'), findsNothing);
      expect(find.text('No payment methods yet'), findsOneWidget);
    },
  );
}
