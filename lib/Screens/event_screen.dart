import 'package:flutter/material.dart';
import 'package:trial_app/Controllers/event.model.dart';
import 'package:trial_app/Services/event_service.dart';
import 'package:trial_app/Services/notification_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class EventScreen extends StatefulWidget {
  final String? userId;
  const EventScreen({super.key, this.userId});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  // Variabel
  final EventService eventService = EventService();
  List<EventModel> events = [];
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _getCurrentLocation();
  }

  // Load events dari Hive
  Future<void> _loadEvents() async {
    await eventService.init();
    final loadedEvents = await eventService.getEvents();

    // Jika belum ada events, buat dummy data
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

    if (mounted) setState(() {});
  }

  // Ambil lokasi user
  Future<void> _getCurrentLocation() async {
    // Cek apakah location service enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location service tidak aktif')),
      );
      return;
    }

    // Cek permission
    LocationPermission permission = await Geolocator.checkPermission();
    
    // Jika belum diizinkan, minta permission
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

    // Jika ditolak permanen
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin lokasi ditolak permanen. Buka settings untuk mengizinkan')),
      );
      return;
    }

    // Ambil lokasi
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

  // Hitung jarak dari user ke event
  double _calculateDistance(EventModel event) {
    if (currentPosition == null) return 0.0;
    return Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      event.latitude,
      event.longitude,
    ) / 1000.0; // Convert ke km
  }

  // Buka Google Maps eksternal dengan 2 lokasi
  Future<void> _openMap(EventModel event) async {
    // Koordinat event
    final eventLat = event.latitude;
    final eventLng = event.longitude;

    // Ambil lokasi user (jika belum ada, minta permission dulu)
    if (currentPosition == null) {
      await _getCurrentLocation();
    }

    // Gunakan lokasi user jika ada, kalau tidak gunakan lokasi event sebagai start
    final userLat = currentPosition?.latitude ?? eventLat;
    final userLng = currentPosition?.longitude ?? eventLng;

    // Format URL Google Maps dengan directions (menampilkan 2 lokasi)
    // Format: https://www.google.com/maps/dir/[start_lat],[start_lng]/[end_lat],[end_lng]
    final googleMapsUrl = 'https://www.google.com/maps/dir/$userLat,$userLng/$eventLat,$eventLng';

    // Buka Google Maps app
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

  // Claim tiket event
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
      // Tampilkan SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiket berhasil di-claim!')),
      );
      
      // Tampilkan notifikasi
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
    if (events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final hasClaimed = widget.userId != null &&
            eventService.hasUserClaimed(widget.userId!, event.id);
        final isFull = event.claimedCount >= event.maxTicket;
        final distance = _calculateDistance(event);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ListTile(
            title: Text(event.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${event.location} • ${event.date.toLocal().toString().split('.')[0]}'),
                Text('Claimed: ${event.claimedCount}/${event.maxTicket}'),
                if (currentPosition != null && distance > 0)
                  Text(
                    distance < 1
                        ? '${(distance * 1000).toStringAsFixed(0)} m away'
                        : '${distance.toStringAsFixed(1)} km away',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: () => _openMap(event),
                  tooltip: 'Buka Google Maps',
                ),
                ElevatedButton(
                  onPressed: (hasClaimed || isFull) ? null : () => _claimTicket(event),
                  child: Text(hasClaimed ? 'Claimed' : 'Claim'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
