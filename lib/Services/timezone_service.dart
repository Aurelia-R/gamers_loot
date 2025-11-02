class TimezoneService {

  static Future<void> initialize() async {

  }

  static Map<String, int> get timezoneOffsets => {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'London': 0,
    'Amerika': -5,
  };

  static DateTime convertToTimezone(DateTime dateTime, String timezone) {

    final utc = dateTime.toUtc();
    

    final offset = timezoneOffsets[timezone] ?? 0;
    

    return utc.add(Duration(hours: offset));
  }

  static String formatDateTime(DateTime dateTime, String timezone) {

    final converted = convertToTimezone(dateTime, timezone);
    

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 
                    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    
    final day = converted.day.toString().padLeft(2, '0');
    final month = months[converted.month - 1];
    final year = converted.year;
    final hour = converted.hour.toString().padLeft(2, '0');
    final minute = converted.minute.toString().padLeft(2, '0');
    
    return '$day $month $year, $hour:$minute ($timezone)';
  }

  static DateTime? parseDateString(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    
    try {

      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  static String? convertEndDate(String? endDateString, String timezone) {
    final dateTime = parseDateString(endDateString);
    if (dateTime == null) return endDateString;
    
    return formatDateTime(dateTime, timezone);
  }
}

