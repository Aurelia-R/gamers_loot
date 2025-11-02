import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:trial_app/Models/giveaway_model.dart';

class GiveawayController {
  final String baseUrl = 'https://gamerpower.com/api/giveaways';

  Future<List<Giveaway>> fetchGiveaways() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Giveaway.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load giveaways');
    }
  }
}
