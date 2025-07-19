import 'package:shared_preferences/shared_preferences.dart';

class CurrencyHelper {
  // Predefined list of common currencies
  static const List<Map<String, String>> supportedCurrencies = [
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥'},
    {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'C\$'},
    {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'CHF'},
    {'code': 'KRW', 'name': 'South Korean Won', 'symbol': '₩'},
    {'code': 'BRL', 'name': 'Brazilian Real', 'symbol': 'R\$'},
    {'code': 'MXN', 'name': 'Mexican Peso', 'symbol': 'MX\$'},
    {'code': 'RUB', 'name': 'Russian Ruble', 'symbol': '₽'},
    {'code': 'ZAR', 'name': 'South African Rand', 'symbol': 'R'},
    {'code': 'NGN', 'name': 'Nigerian Naira', 'symbol': '₦'},
    {'code': 'EGP', 'name': 'Egyptian Pound', 'symbol': 'E£'},
    {'code': 'PHP', 'name': 'Philippine Peso', 'symbol': '₱'},
    {'code': 'THB', 'name': 'Thai Baht', 'symbol': '฿'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': 'S\$'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit', 'symbol': 'RM'},
  ];

  // Default currency
  static const String defaultCurrency = 'USD';

  /// Get the currently selected currency code
  static Future<String> getCurrentCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_currency') ?? defaultCurrency;
  }

  /// Set the selected currency
  static Future<void> setCurrency(String currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_currency', currencyCode);
  }

  /// Get currency symbol for the current selected currency
  static Future<String> getCurrentCurrencySymbol() async {
    final currentCurrency = await getCurrentCurrency();
    return getCurrencySymbol(currentCurrency);
  }

  /// Get currency symbol for a specific currency code
  static String getCurrencySymbol(String currencyCode) {
    final currency = supportedCurrencies.firstWhere(
      (curr) => curr['code'] == currencyCode,
      orElse: () => supportedCurrencies.first,
    );
    return currency['symbol'] ?? '\$';
  }

  /// Get currency name for a specific currency code
  static String getCurrencyName(String currencyCode) {
    final currency = supportedCurrencies.firstWhere(
      (curr) => curr['code'] == currencyCode,
      orElse: () => supportedCurrencies.first,
    );
    return currency['name'] ?? 'US Dollar';
  }

  /// Format amount with currency symbol
  static Future<String> formatAmount(double amount) async {
    final symbol = await getCurrentCurrencySymbol();
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Format amount with specific currency
  static String formatAmountWithCurrency(double amount, String currencyCode) {
    final symbol = getCurrencySymbol(currencyCode);
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Get all supported currencies for selection
  static List<Map<String, String>> getAllCurrencies() {
    return List.from(supportedCurrencies);
  }
}
