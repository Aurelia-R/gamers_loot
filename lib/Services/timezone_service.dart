class TimezoneService {
  // Inisialisasi timezone data (untuk kompatibilitas, tidak perlu karena pakai manual offset)
  static Future<void> initialize() async {
    // Tidak perlu initialize karena pakai manual offset
  }

  // Timezone offset dalam jam dari UTC
  static Map<String, int> get timezoneOffsets => {
    'WIB': 7,   // Western Indonesian Time (UTC+7)
    'WITA': 8,  // Central Indonesian Time (UTC+8)
    'WIT': 9,   // Eastern Indonesian Time (UTC+9)
    'London': 0, // London (UTC+0, atau UTC+1 saat BST)
    'Amerika': -5, // Eastern Time (UTC-5, atau UTC-4 saat DST)
  };

  // Convert DateTime ke timezone tertentu
  static DateTime convertToTimezone(DateTime dateTime, String timezone) {
    // Get UTC time
    final utc = dateTime.toUtc();
    
    // Get offset untuk timezone
    final offset = timezoneOffsets[timezone] ?? 0;
    
    // Convert ke timezone dengan menambahkan offset
    return utc.add(Duration(hours: offset));
  }

  // Format DateTime ke string dengan format yang mudah dibaca
  static String formatDateTime(DateTime dateTime, String timezone) {
    // Convert ke timezone yang dipilih
    final converted = convertToTimezone(dateTime, timezone);
    
    // Format: "DD MMM YYYY, HH:mm (Timezone)"
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 
                    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    
    final day = converted.day.toString().padLeft(2, '0');
    final month = months[converted.month - 1];
    final year = converted.year;
    final hour = converted.hour.toString().padLeft(2, '0');
    final minute = converted.minute.toString().padLeft(2, '0');
    
    return '$day $month $year, $hour:$minute ($timezone)';
  }

  // Parse string date ke DateTime
  static DateTime? parseDateString(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    
    try {
      // Format dari API biasanya: "2025-11-06 23:59:00"
      // Parse sebagai UTC
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Convert end date string ke timezone dan format
  static String? convertEndDate(String? endDateString, String timezone) {
    final dateTime = parseDateString(endDateString);
    if (dateTime == null) return endDateString;
    
    return formatDateTime(dateTime, timezone);
  }
}

