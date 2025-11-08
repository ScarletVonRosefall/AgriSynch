import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyHelper {
  // Frankfurter API - FREE currency exchange rates (European Central Bank)
  // No API key required, unlimited requests! 🎉
  static const String _baseUrl = 'https://api.frankfurter.app';

  // Predefined list of common currencies
  static const List<Map<String, String>> supportedCurrencies = [
    {'code': 'PHP', 'name': '🇵🇭 Philippine Peso', 'symbol': '₱'},
    {'code': 'USD', 'name': '🇺🇸 US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': '🇪🇺 Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': '🇬🇧 British Pound', 'symbol': '£'},
    {'code': 'JPY', 'name': '🇯🇵 Japanese Yen', 'symbol': '¥'},
    {'code': 'CNY', 'name': '🇨🇳 Chinese Yuan', 'symbol': '¥'},
    {'code': 'AUD', 'name': '🇦🇺 Australian Dollar', 'symbol': 'A\$'},
    {'code': 'CAD', 'name': '🇨🇦 Canadian Dollar', 'symbol': 'C\$'},
    {'code': 'KRW', 'name': '🇰🇷 South Korean Won', 'symbol': '₩'},
    {'code': 'SGD', 'name': '🇸🇬 Singapore Dollar', 'symbol': 'S\$'},
    {'code': 'MYR', 'name': '🇲🇾 Malaysian Ringgit', 'symbol': 'RM'},
    {'code': 'THB', 'name': '🇹🇭 Thai Baht', 'symbol': '฿'},
    {'code': 'INR', 'name': '🇮🇳 Indian Rupee', 'symbol': '₹'},
    {'code': 'CHF', 'name': '🇨🇭 Swiss Franc', 'symbol': 'CHF'},
  ];
  
  // Fallback symbols for devices that don't render special currency symbols
  static const Map<String, String> fallbackSymbols = {
    'PHP': 'P',  // Fallback for Philippine Peso if ₱ doesn't render
    'KRW': 'W',  // Fallback for Korean Won if ₩ doesn't render
    'THB': 'B',  // Fallback for Thai Baht if ฿ doesn't render
    'INR': 'Rs', // Fallback for Indian Rupee if ₹ doesn't render
  };

  // Default currency
  static const String defaultCurrency = 'PHP';

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
    // Use fallback symbol if available (for better device compatibility)
    if (fallbackSymbols.containsKey(currencyCode)) {
      return fallbackSymbols[currencyCode]!;
    }
    
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

  /// Get latest exchange rates from Frankfurter API
  static Future<Map<String, double>> getExchangeRates({
    String baseCurrency = 'PHP',
    List<String>? targetCurrencies,
  }) async {
    try {
      // Build URL with target currencies if specified
      String url = '$_baseUrl/latest?from=$baseCurrency';
      if (targetCurrencies != null && targetCurrencies.isNotEmpty) {
        url += '&to=${targetCurrencies.join(',')}';
      }

      print('Fetching exchange rates from: $url');

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Exchange rates received: ${data['rates']}');

        // Convert rates to Map<String, double>
        final Map<String, double> rates = {};
        final ratesData = data['rates'] as Map<String, dynamic>;
        ratesData.forEach((currency, rate) {
          rates[currency] = (rate as num).toDouble();
        });

        return rates;
      } else {
        throw Exception(
            'Failed to fetch exchange rates (${response.statusCode})');
      }
    } catch (e) {
      print('Error fetching exchange rates: $e');
      rethrow;
    }
  }

  /// Convert amount from one currency to another using Frankfurter API
  static Future<double> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    try {
      if (fromCurrency == toCurrency) {
        return amount; // No conversion needed
      }

      final url =
          '$_baseUrl/latest?amount=$amount&from=$fromCurrency&to=$toCurrency';
      print('Converting: $amount $fromCurrency to $toCurrency');

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final convertedAmount = (data['rates'][toCurrency] as num).toDouble();
        print('Converted: $amount $fromCurrency = $convertedAmount $toCurrency');
        return convertedAmount;
      } else {
        throw Exception('Failed to convert currency (${response.statusCode})');
      }
    } catch (e) {
      print('Error converting currency: $e');
      rethrow;
    }
  }

  /// Get exchange rate between two currencies
  static Future<double> getExchangeRate({
    required String fromCurrency,
    required String toCurrency,
  }) async {
    try {
      if (fromCurrency == toCurrency) {
        return 1.0; // Same currency
      }

      final url = '$_baseUrl/latest?from=$fromCurrency&to=$toCurrency';
      print('Getting rate: $fromCurrency -> $toCurrency');

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = (data['rates'][toCurrency] as num).toDouble();
        print('Rate: 1 $fromCurrency = $rate $toCurrency');
        return rate;
      } else {
        throw Exception('Failed to get exchange rate (${response.statusCode})');
      }
    } catch (e) {
      print('Error getting exchange rate: $e');
      rethrow;
    }
  }
}

/// Currency conversion data model
class CurrencyConversion {
  final String fromCurrency;
  final String toCurrency;
  final double amount;
  final double convertedAmount;
  final double exchangeRate;
  final DateTime timestamp;

  CurrencyConversion({
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
    required this.convertedAmount,
    required this.exchangeRate,
    required this.timestamp,
  });

  String get formattedFrom =>
      CurrencyHelper.formatAmountWithCurrency(amount, fromCurrency);
  String get formattedTo =>
      CurrencyHelper.formatAmountWithCurrency(convertedAmount, toCurrency);
  String get formattedRate =>
      '1 $fromCurrency = ${exchangeRate.toStringAsFixed(4)} $toCurrency';
}

