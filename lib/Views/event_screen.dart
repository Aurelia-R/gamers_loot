import 'package:flutter/material.dart';
import 'package:trial_app/Controllers/event.model.dart';
import 'package:trial_app/Services/event_service.dart';
import 'package:trial_app/Services/notification_service.dart';
import 'package:trial_app/theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class EventScreen extends StatefulWidget {
  final String? userId;
  const EventScreen({super.key, this.userId});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {

  final EventService eventService = EventService();
  List<EventModel> events = [];
  Position? currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _getCurrentLocation();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    await eventService.init();
    final loadedEvents = await eventService.getEvents();

    if (loadedEvents.isEmpty) {
      events = [
        EventModel(
          id: '1',
          name: 'Gaming Meetup Jakarta',
          location: 'Jakarta',
          latitude: -6.200000,
          longitude: 106.816666,
          date: DateTime.now().add(const Duration(days: 3)),
          maxTicket: 10,
        ),
        EventModel(
          id: '2',
          name: 'Indie Game Expo',
          location: 'Bandung',
          latitude: -6.914744,
          longitude: 107.609810,
          date: DateTime.now().add(const Duration(days: 7)),
          maxTicket: 5,
        ),
      ];
      await eventService.saveEvents(events);
    } else {
      events = loadedEvents;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location service tidak aktif')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi diperlukan untuk melihat jarak')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin lokasi ditolak permanen. Buka settings untuk mengizinkan')),
      );
      return;
    }

    try {
      currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil lokasi: $e')),
      );
    }
  }

  double _calculateDistance(EventModel event) {
    if (currentPosition == null) return 0.0;
    return Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      event.latitude,
      event.longitude,
    ) / 1000.0;
  }

  String _formatDate(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final localDate = date.toLocal();
    final dayName = days[localDate.weekday - 1];
    final day = localDate.day.toString().padLeft(2, '0');
    final month = months[localDate.month - 1];
    final year = localDate.year;
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    return '$dayName, $day $month $year • $hour:$minute';
  }

  Future<void> _openMap(EventModel event) async {

    final eventLat = event.latitude;
    final eventLng = event.longitude;

    if (currentPosition == null) {
      await _getCurrentLocation();
    }

    final userLat = currentPosition?.latitude ?? eventLat;
    final userLng = currentPosition?.longitude ?? eventLng;

    final googleMapsUrl = 'https://www.google.com/maps/dir/$userLat,$userLng/$eventLat,$eventLng';

    final uri = Uri.parse(googleMapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
      );
    }
  }

  Future<void> _claimTicket(EventModel event) async {
    if (widget.userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID tidak ditemukan')),
      );
      return;
    }

    final success = await eventService.claimTicket(widget.userId!, event);
    if (!mounted) return;

    if (success) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiket berhasil di-claim!')),
      );
      

      await NotificationService.showTicketClaimedNotification(event.name);
      
      await _loadEvents();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal claim: Sudah pernah claim atau tiket habis')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.green),
        ),
      );
    }

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Tidak ada event tersedia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Event akan muncul di sini',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final hasClaimed = widget.userId != null &&
            eventService.hasUserClaimed(widget.userId!, event.id);
        final isFull = event.claimedCount >= event.maxTicket;
        final distance = _calculateDistance(event);
        final isPastEvent = event.date.isBefore(DateTime.now());
        final formattedDate = _formatDate(event.date);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openMap(event),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navyDark,
                              ),
                            ),
                            const SizedBox(height: 8),

                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    event.location,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: hasClaimed
                              ? AppTheme.green
                              : isFull
                                  ? Colors.red.shade100
                                  : isPastEvent
                                      ? Colors.grey.shade300
                                      : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          hasClaimed
                              ? 'Claimed'
                              : isFull
                                  ? 'Full'
                                  : isPastEvent
                                      ? 'Ended'
                                      : 'Available',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: hasClaimed
                                ? Colors.white
                                : isFull
                                    ? Colors.red.shade700
                                    : isPastEvent
                                        ? Colors.grey.shade700
                                        : Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [

                      if (currentPosition != null && distance > 0)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_searching, size: 16, color: Colors.blue.shade700),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    distance < 1
                                        ? '${(distance * 1000).toStringAsFixed(0)} m'
                                        : '${distance.toStringAsFixed(1)} km',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (currentPosition != null && distance > 0) const SizedBox(width: 8),

                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.confirmation_number, size: 16, color: AppTheme.green),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${event.claimedCount}/${event.maxTicket}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [

                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openMap(event),
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text('Maps'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.navyDark,
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: (hasClaimed || isFull || isPastEvent)
                              ? null
                              : () => _claimTicket(event),
                          icon: Icon(
                            hasClaimed ? Icons.check_circle : Icons.add_circle_outline,
                            size: 18,
                          ),
                          label: Text(hasClaimed ? 'Claimed' : 'Claim Ticket'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasClaimed ? Colors.grey : AppTheme.green,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
