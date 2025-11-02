import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {

  static const String apiUrl = 'https://open.er-api.com/v6/latest/USD';
  

  Map<String, double>? _rates;
  DateTime? _lastFetch;

  static const Duration cacheDuration = Duration(hours: 1);

  Future<Map<String, double>> getExchangeRates() async {

    if (_rates != null && _lastFetch != null) {
      final now = DateTime.now();
      if (now.difference(_lastFetch!) < cacheDuration) {
        return _rates!;
      }
    }

    try {

      final response = await http.get(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;
        

        _rates = {};
        rates.forEach((key, value) {
          _rates![key] = (value as num).toDouble();
        });
        

        _rates!['USD'] = 1.0;
        

        _lastFetch = DateTime.now();
        
        return _rates!;
      } else {
        throw Exception('Gagal mengambil data dari API');
      }
    } catch (e) {

      if (_rates != null) return _rates!;
      

      return {
        'USD': 1.0,
        'IDR': 16648.0,
        'GBP': 0.76,
        'EUR': 0.87,
        'JPY': 154.0,
      };
    }
  }

  Future<String?> convertPrice(String? usdPrice, String targetCurrency) async {

    if (usdPrice == null || usdPrice.isEmpty) return null;
    

    final priceStr = usdPrice.replaceAll(RegExp(r'[^\d.]'), '');
    final price = double.tryParse(priceStr);
    

    if (price == null) return usdPrice;

    final rates = await getExchangeRates();
    final rate = rates[targetCurrency];
    

    if (rate == null) return usdPrice;

    final convertedPrice = price * rate;

    String symbol = _getCurrencySymbol(targetCurrency);
    return '$symbol${convertedPrice.toStringAsFixed(2)}';
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'IDR':
        return 'Rp ';
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      case 'JPY':
        return '¥';
      default:
        return '$currency ';
    }
  }
}

