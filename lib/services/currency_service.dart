// lib/services/currency_service.dart

class CurrencyService {
  CurrencyService._();
  static final CurrencyService instance = CurrencyService._();

  // List of supported currency codes
  final List<String> supported = ['USD', 'EUR', 'GBP', 'JPY', 'AUD'];

  // Currently selected currency (defaults to USD)
  String _current = 'USD';
  String get current => _current;
  set current(String c) {
    if (supported.contains(c)) _current = c;
  }
}
