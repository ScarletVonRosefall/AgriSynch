# Currency Converter Feature

## Overview
AgriSynch now includes a real-time currency converter powered by the Frankfurter API, providing free and unlimited exchange rate data from the European Central Bank.

## Features

### ✨ **Frankfurter API Integration**
- **FREE** - No API key required
- **Unlimited** - No rate limits or request quotas
- **Reliable** - European Central Bank official rates
- **Real-time** - Always up-to-date exchange rates
- **30+ Currencies** - Including PHP, USD, EUR, JPY, GBP, and more

### 💱 **Supported Currencies**
1. 🇵🇭 Philippine Peso (PHP)
2. 🇺🇸 US Dollar (USD)
3. 🇪🇺 Euro (EUR)
4. 🇬🇧 British Pound (GBP)
5. 🇯🇵 Japanese Yen (JPY)
6. 🇨🇳 Chinese Yuan (CNY)
7. 🇦🇺 Australian Dollar (AUD)
8. 🇨🇦 Canadian Dollar (CAD)
9. 🇰🇷 South Korean Won (KRW)
10. 🇸🇬 Singapore Dollar (SGD)
11. 🇲🇾 Malaysian Ringgit (MYR)
12. 🇹🇭 Thai Baht (THB)
13. 🇮🇳 Indian Rupee (INR)
14. 🇨🇭 Swiss Franc (CHF)

## How to Use

### **1. Access Currency Converter**
- From Farmer Home: Tap the green "Currency Converter" card
- Shows real-time exchange rates

### **2. Convert Currency**
1. **Enter Amount**: Type the amount you want to convert
2. **Select From Currency**: Choose source currency (default: PHP)
3. **Select To Currency**: Choose target currency (default: USD)
4. **Swap**: Tap the swap button to quickly reverse conversion
5. **View Result**: See converted amount in large display

### **3. Exchange Rate Info**
- Shows current exchange rate (e.g., "1 PHP = 0.0179 USD")
- Updates automatically when you change currencies
- Rates are from European Central Bank

## Technical Implementation

### **Files Created/Modified:**

#### `lib/shared/currency_helper.dart`
**Purpose**: Currency conversion logic and API integration

**Key Methods**:
```dart
// Get exchange rates
Future<Map<String, double>> getExchangeRates({
  String baseCurrency = 'PHP',
  List<String>? targetCurrencies,
})

// Convert specific amount
Future<double> convertCurrency({
  required double amount,
  required String fromCurrency,
  required String toCurrency,
})

// Get single exchange rate
Future<double> getExchangeRate({
  required String fromCurrency,
  required String toCurrency,
})

// Format with currency symbol
String formatCurrency(double amount, String currencyCode)
```

#### `lib/shared/AgriCurrencyPage.dart`
**Purpose**: Currency converter user interface

**Features**:
- Amount input with decimal validation
- Currency dropdown selectors with flags
- Swap currencies button
- Large result display
- Exchange rate info card
- Error handling with retry
- Dark mode support

#### `lib/farmer/AgriSynchHomePage.dart`
**Modified**: Added currency converter card to home page

**New Widget**: `_buildCurrencyCard()`
- Green gradient design
- Currency exchange icon
- Tap to open converter
- Shows "PHP • USD • EUR • More"

## API Details

### **Frankfurter API**
- **Base URL**: `https://api.frankfurter.app`
- **Documentation**: https://www.frankfurter.app/docs
- **Data Source**: European Central Bank
- **Update Frequency**: Daily (weekdays)
- **Timeout**: 10 seconds
- **No Authentication**: Works immediately

### **API Endpoints Used**:

1. **Get Latest Rates**:
   ```
   GET https://api.frankfurter.app/latest?from=PHP
   ```

2. **Convert Amount**:
   ```
   GET https://api.frankfurter.app/latest?amount=100&from=PHP&to=USD
   ```

3. **Specific Currencies**:
   ```
   GET https://api.frankfurter.app/latest?from=PHP&to=USD,EUR,JPY
   ```

### **Response Format**:
```json
{
  "amount": 100,
  "base": "PHP",
  "date": "2025-11-08",
  "rates": {
    "USD": 1.79,
    "EUR": 1.65
  }
}
```

## Use Cases for AgriSynch

### **1. International Buyers**
- Convert crop prices from PHP to USD/EUR
- Compare prices in their local currency
- Calculate total costs for imports

### **2. Farmers Selling Abroad**
- See product value in foreign currencies
- Plan pricing for international markets
- Track currency fluctuations

### **3. Price Planning**
- Set competitive prices in multiple currencies
- Understand market value globally
- Adjust pricing based on exchange rates

### **4. Financial Planning**
- Convert earnings to other currencies
- Plan international transactions
- Budget for imported supplies

## Error Handling

### **Connection Issues**
- 10-second timeout for API requests
- Shows error message with retry button
- Graceful fallback if API is unreachable

### **Invalid Input**
- Validates decimal amounts (max 2 decimal places)
- Prevents non-numeric characters
- Handles empty input

### **Same Currency**
- Detects when from/to currencies are identical
- Returns amount without API call
- Efficient for unnecessary requests

## Benefits

✅ **No Setup Required** - Works immediately, no API key  
✅ **Always Free** - Unlimited conversions  
✅ **Accurate Data** - European Central Bank rates  
✅ **Fast** - Quick API responses  
✅ **Reliable** - High uptime, well-maintained  
✅ **Perfect for Demos** - Evaluators can test instantly  
✅ **International Ready** - Supports global agriculture trade  

## Future Enhancements

Potential additions:
- Historical rate charts
- Price alerts for specific exchange rates
- Multi-currency product pricing
- Currency preference saving
- Offline mode with cached rates
- Calculator mode for quick conversions

---

**Last Updated**: November 8, 2025  
**Version**: 1.0 with Frankfurter API  
**API Provider**: Frankfurter (European Central Bank)
