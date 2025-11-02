import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileController {
  final supabase = Supabase.instance.client;

  Future<String?> uploadPhoto(String userId, File file) async {
    try {
      final name = file.path.split(RegExp(r'[\\/]')).last;
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
      final mime = ext == 'png'
          ? 'image/png'
          : ext == 'webp'
              ? 'image/webp'
              : 'image/jpeg';
      final filePath = 'user_$userId.$ext';

      final bytes = await file.readAsBytes();
      await supabase.storage.from('profile_pics').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: mime,
            ),
          );

      final publicUrl = supabase.storage
          .from('profile_pics')
          .getPublicUrl(filePath);

      await supabase.from('profiles').update({'photo_url': publicUrl}).eq('id', userId);
      return publicUrl;
    } catch (e) {

      print('uploadPhoto error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProfile(String id) async {
    try {
      final data = await supabase.from('profiles').select().eq('id', id).maybeSingle();
      return data;
    } catch (e) {

      print('getProfile error: $e');
      return null;
    }
  }

  Future<void> updateProfile(String id,
      {String? username, String? email, String? photoUrl}) async {
    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username;
    if (email != null) updates['email'] = email;
    if (photoUrl != null) updates['photo_url'] = photoUrl;

    await supabase.from('profiles').update(updates).eq('id', id);
  }

  Future<void> deleteAccount(String id) async {
    await supabase.from('profiles').delete().eq('id', id);
  }
}
