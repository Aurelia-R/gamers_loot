import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  // URL API
  static const String apiUrl = 'https://open.er-api.com/v6/latest/USD';
  
  // Cache untuk rates (supaya tidak fetch terus-terusan)
  Map<String, double>? _rates;
  DateTime? _lastFetch;

  // Cache selama 1 jam
  static const Duration cacheDuration = Duration(hours: 1);

  // Ambil exchange rates dari API
  Future<Map<String, double>> getExchangeRates() async {
    // Cek cache dulu
    if (_rates != null && _lastFetch != null) {
      final now = DateTime.now();
      if (now.difference(_lastFetch!) < cacheDuration) {
        return _rates!;
      }
    }

    try {
      // Fetch dari API
      final response = await http.get(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;
        
        // Convert ke Map<String, double>
        _rates = {};
        rates.forEach((key, value) {
          _rates![key] = (value as num).toDouble();
        });
        
        // Tambahkan USD sebagai base (rate = 1.0)
        _rates!['USD'] = 1.0;
        
        // Simpan waktu fetch
        _lastFetch = DateTime.now();
        
        return _rates!;
      } else {
        throw Exception('Gagal mengambil data dari API');
      }
    } catch (e) {
      // Jika error, return default rates
      if (_rates != null) return _rates!;
      
      // Default rates jika API error
      return {
        'USD': 1.0,
        'IDR': 16648.0,
        'GBP': 0.76,
        'EUR': 0.87,
        'JPY': 154.0,
      };
    }
  }

  // Konversi harga dari USD ke mata uang lain
  Future<String?> convertPrice(String? usdPrice, String targetCurrency) async {
    // Cek apakah ada harga
    if (usdPrice == null || usdPrice.isEmpty) return null;
    
    // Ambil angka dari string (contoh: "$19.99" -> 19.99)
    final priceStr = usdPrice.replaceAll(RegExp(r'[^\d.]'), '');
    final price = double.tryParse(priceStr);
    
    // Jika tidak bisa parse, return harga asli
    if (price == null) return usdPrice;

    // Ambil exchange rates
    final rates = await getExchangeRates();
    final rate = rates[targetCurrency];
    
    // Jika rate tidak ada, return harga asli
    if (rate == null) return usdPrice;

    // Hitung harga setelah konversi
    final convertedPrice = price * rate;

    // Format dengan symbol mata uang
    String symbol = _getCurrencySymbol(targetCurrency);
    return '$symbol${convertedPrice.toStringAsFixed(2)}';
  }

  // Ambil symbol mata uang
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

