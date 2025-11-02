import 'package:hive_flutter/hive_flutter.dart';

class WishlistService {
  static const String _boxName = 'wishlistBox';

  Future<void> _init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  Future<Set<int>> getAll(String userId) async {
    await _init();
    try {
      final box = Hive.box(_boxName);
      final raw = box.get(userId, defaultValue: <int>[]) ?? <int>[];
      final list = List<int>.from(raw.cast<int>());
      return Set<int>.from(list);
    } catch (_) {
      return {};
    }
  }

  Future<void> toggle(String userId, int id) async {
    await _init();
    final box = Hive.box(_boxName);
    final current = await getAll(userId);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    await box.put(userId, current.toList());
  }

  Future<bool> exists(String userId, int id) async {
    final set = await getAll(userId);
    return set.contains(id);
  }
}


