import 'package:hive_flutter/hive_flutter.dart';
import 'package:trial_app/Models/user_model.dart';

class SessionService {
  static const String _boxName = 'sessionBox';
  static const String _userKey = 'currentUser';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Map>(_boxName);
    }
  }

  Box<Map> _box() => Hive.box<Map>(_boxName);

  Future<void> saveUser(UserModel user) async {
    await _box().put(_userKey, user.toJson());
  }

  UserModel? getUser() {
    try {
      final data = _box().get(_userKey);
      if (data == null) return null;
      final map = Map<String, dynamic>.from(data);
      return UserModel.fromJson(map);
    } catch (e) {
      _box().delete(_userKey);
      return null;
    }
  }

  Future<void> clear() async {
    await _box().delete(_userKey);
  }
}


