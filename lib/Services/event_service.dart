import 'package:hive_flutter/hive_flutter.dart';
import 'package:trial_app/Controllers/event.model.dart';
import 'dart:convert';

class EventService {
  static const boxName = 'events';
  static const userTicketsBoxName = 'userTickets';

  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    if (!Hive.isBoxOpen(userTicketsBoxName)) {
      await Hive.openBox(userTicketsBoxName);
    }
  }

  Future<List<EventModel>> getEvents() async {
    await init();
    try {
      final box = Hive.box(boxName);
      final raw = box.get('list', defaultValue: '[]') as String;
      final List data = jsonDecode(raw) as List;
      return data.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveEvents(List<EventModel> events) async {
    await init();
    final box = Hive.box(boxName);
    final raw = jsonEncode(events.map((e) => e.toJson()).toList());
    await box.put('list', raw);
  }

  Future<bool> claimTicket(String userId, EventModel event) async {
    await init();
    

    if (hasUserClaimed(userId, event.id)) {

      print('User $userId sudah claim event ${event.id}');
      return false;
    }
    

    if (event.claimedCount >= event.maxTicket) {

      print('Event ${event.id} sudah habis tiketnya');
      return false;
    }
    

    event.claimedCount++;
    final events = await getEvents();
    final index = events.indexWhere((e) => e.id == event.id);
    if (index != -1) events[index] = event;
    await saveEvents(events);
    

    final ticketsBox = Hive.box(userTicketsBoxName);
    final raw = ticketsBox.get(userId, defaultValue: <String>[]) ?? <String>[];
    final userTickets = List<String>.from(raw.cast<String>());
    
    final eventIdStr = event.id.toString();
    if (!userTickets.contains(eventIdStr)) {
      userTickets.add(eventIdStr);
      await ticketsBox.put(userId, userTickets);
    }
    
    return true;
  }

  bool hasUserClaimed(String userId, dynamic eventId) {
    try {
      final ticketsBox = Hive.box(userTicketsBoxName);
      final raw = ticketsBox.get(userId, defaultValue: <String>[]) ?? <String>[];
      final userTickets = List<String>.from(raw.cast<String>());
      return userTickets.contains(eventId.toString());
    } catch (_) {
      return false;
    }
  }

  Future<List<EventModel>> getMyTickets(String userId) async {
    await init();
    try {
      final ticketsBox = Hive.box(userTicketsBoxName);
      final raw = ticketsBox.get(userId, defaultValue: <String>[]) ?? <String>[];
      final userTickets = List<String>.from(raw.cast<String>());
      if (userTickets.isEmpty) return [];
      
      final allEvents = await getEvents();
      return allEvents.where((e) => userTickets.contains(e.id.toString())).toList();
    } catch (_) {
      return [];
    }
  }
}
