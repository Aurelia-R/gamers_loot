class Giveaway {
  final int id;
  final String title;
  final String? worth;
  final String? thumbnail;
  final String? platform;
  final String? openGiveawayUrl;
  final String? publishedDate;
  final String? endDate;
  final String? description;
  final int? users;

  Giveaway({
    required this.id,
    required this.title,
    this.worth,
    this.thumbnail,
    this.platform,
    this.openGiveawayUrl,
    this.publishedDate,
    this.endDate,
    this.description,
    this.users,
  });

  factory Giveaway.fromJson(Map<String, dynamic> json) {
    final dynamic rawUsers = json['users'];
    final int? parsedUsers = rawUsers == null
        ? null
        : (rawUsers is int ? rawUsers : int.tryParse('$rawUsers'));

    return Giveaway(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      worth: json['worth'],
      thumbnail: json['thumbnail'],
      platform: json['platforms'],
      openGiveawayUrl: json['open_giveaway_url'],
      publishedDate: json['published_date'],
      endDate: json['end_date'],
      description: json['description'],
      users: parsedUsers,
    );
  }
}
