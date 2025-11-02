import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trial_app/Models/user_model.dart';

class SupabaseService {
  final client = Supabase.instance.client;

  Future<bool> registerUser(UserModel user) async {
    try {
      await client.from('profiles').insert(user.toJson());
      return true;
    } catch (e) {
      print('registerUser error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final res = await client
          .from('profiles')
          .select()
          .eq('email', email)
          .maybeSingle();
      return res;
    } catch (e) {
      print('getUserByEmail error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    return await client.from('events').select();
  }
}
