import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'currency_helper.dart';
import 'theme_helper.dart';
import 'notification_helper.dart';
import 'AgriNotificationPage.dart';

class AgriCurrencyPage extends StatefulWidget {
  const AgriCurrencyPage({super.key});

  @override
  State<AgriCurrencyPage> createState() => _AgriCurrencyPageState();
}

class _AgriCurrencyPageState extends State<AgriCurrencyPage> {
  final _themeNotifier = ThemeNotifier();
  int unreadNotifications = 0;
  
  String fromCurrency = 'PHP';
  String toCurrency = 'USD';
  double amount = 100.0;
  double? convertedAmount;
  double? exchangeRate;
  bool isLoading = false;
  String? errorMessage;
  
  final TextEditingController _amountController = TextEditingController(text: '100');

  @override
  void initState() {
    super.initState();
    _themeNotifier.darkModeNotifier.addListener(_onThemeChanged);
    _loadUnreadNotifications();
    _convertCurrency();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _themeNotifier.darkModeNotifier.removeListener(_onThemeChanged);
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final count = await NotificationHelper.getUnreadCount();
      if (mounted) {
        setState(() => unreadNotifications = count);
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _convertCurrency() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final rate = await CurrencyHelper.getExchangeRate(
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
      );

      final converted = await CurrencyHelper.convertCurrency(
        amount: amount,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
      );

      if (mounted) {
        setState(() {
          exchangeRate = rate;
          convertedAmount = converted;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to get exchange rate. Please try again.';
          convertedAmount = null;
          exchangeRate = null;
        });
      }
    }
  }

  void _swapCurrencies() {
    setState(() {
      final temp = fromCurrency;
      fromCurrency = toCurrency;
      toCurrency = temp;
    });
    _convertCurrency();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeNotifier.isDarkMode;

    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(isDarkMode),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 20, 20, 20),
            width: double.infinity,
            decoration: ThemeHelper.getHeaderDecoration(isDark: isDarkMode),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Currency Converter',
                        style: ThemeHelper.getHeaderTextStyle(isDark: isDarkMode),
                      ),
                      Text(
                        'Real-time Exchange Rates',
                        style: ThemeHelper.getSubHeaderTextStyle(isDark: isDarkMode),
                      ),
                    ],
                  ),
                ),
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AgriNotificationPage(),
                            ),
                          );
                          _loadUnreadNotifications();
                        },
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    if (unreadNotifications > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadNotifications > 9
                                ? '9+'
                                : unreadNotifications.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Amount Input Card
                  _buildAmountCard(isDarkMode),
                  const SizedBox(height: 20),

                  // From Currency
                  _buildCurrencySelector(
                    isDarkMode,
                    'From',
                    fromCurrency,
                    (value) {
                      setState(() => fromCurrency = value!);
                      _convertCurrency();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Swap Button
                  Center(
                    child: IconButton(
                      onPressed: _swapCurrencies,
                      icon: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF00C853),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.swap_vert,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // To Currency
                  _buildCurrencySelector(
                    isDarkMode,
                    'To',
                    toCurrency,
                    (value) {
                      setState(() => toCurrency = value!);
                      _convertCurrency();
                    },
                  ),
                  const SizedBox(height: 24),

                  // Result Card
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (errorMessage != null)
                    _buildErrorCard(isDarkMode)
                  else if (convertedAmount != null)
                    _buildResultCard(isDarkMode),

                  const SizedBox(height: 24),

                  // Exchange Rate Info
                  if (exchangeRate != null && !isLoading)
                    _buildExchangeRateInfo(isDarkMode),

                  const SizedBox(height: 24),

                  // Powered by Frankfurter
                  _buildPoweredBy(isDarkMode),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '0.00',
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.white30 : Colors.black26,
              ),
            ),
            onChanged: (value) {
              final parsed = double.tryParse(value);
              if (parsed != null) {
                setState(() => amount = parsed);
                _convertCurrency();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector(
    bool isDarkMode,
    String label,
    String selectedCurrency,
    void Function(String?) onChanged,
  ) {
    final currencies = CurrencyHelper.getAllCurrencies();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<String>(
              value: selectedCurrency,
              isExpanded: true,
              underline: Container(),
              dropdownColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              items: currencies.map((currency) {
                return DropdownMenuItem<String>(
                  value: currency['code'],
                  child: Text('${currency['name']} (${currency['symbol']})'),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(bool isDarkMode) {
    final fromSymbol = CurrencyHelper.getCurrencySymbol(fromCurrency);
    final toSymbol = CurrencyHelper.getCurrencySymbol(toCurrency);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [const Color(0xFF2E7D32), const Color(0xFF4CAF50)]
              : [const Color(0xFF00C853), const Color(0xFF4CAF50)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Converted Amount',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$toSymbol${convertedAmount!.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$fromSymbol${amount.toStringAsFixed(2)} $fromCurrency',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.red,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _convertCurrency,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeRateInfo(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1B5E20).withOpacity(0.3)
            : const Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF81C784),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: isDarkMode ? Colors.white70 : const Color(0xFF2E7D32),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '1 $fromCurrency = ${exchangeRate!.toStringAsFixed(4)} $toCurrency',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : const Color(0xFF1B5E20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoweredBy(bool isDarkMode) {
    return Column(
      children: [
        Text(
          'Powered by Frankfurter API',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: isDarkMode ? Colors.white54 : Colors.black38,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Real-time rates from European Central Bank',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: isDarkMode ? Colors.white38 : Colors.black26,
          ),
        ),
      ],
    );
  }
}
