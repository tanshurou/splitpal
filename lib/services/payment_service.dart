// lib/services/payment_service.dart

import '../pages/banking_details_page.dart'; // for PaymentMethod

class PaymentService {
  // 1) Singleton boilerplate
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  // 2) Backing list
  final List<PaymentMethod> _methods = [
    PaymentMethod(name: 'Visa', details: '**** 4242'),
    PaymentMethod(name: 'Mastercard', details: '**** 5454'),
  ];

  // 3) Read‐only view
  List<PaymentMethod> get methods => List.unmodifiable(_methods);

  // 4) Mutators
  void addMethod(PaymentMethod m) => _methods.add(m);
  void deleteMethodAt(int i) => _methods.removeAt(i);
}
