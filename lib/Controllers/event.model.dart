class EventModel {
  final String id;
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  final DateTime date;
  int claimedCount;
  final int maxTicket;

  EventModel({
    required this.id,
    required this.name,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.date,
    this.claimedCount = 0,
    this.maxTicket = 50,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'date': date.toIso8601String(),
        'claimedCount': claimedCount,
        'maxTicket': maxTicket,
      };

  factory EventModel.fromJson(Map<String, dynamic> json) => EventModel(
        id: json['id'],
        name: json['name'],
        location: json['location'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        date: DateTime.parse(json['date']),
        claimedCount: json['claimedCount'] ?? 0,
        maxTicket: json['maxTicket'] ?? 50,
      );
}
