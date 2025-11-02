import 'package:flutter/material.dart';
import 'dart:io';
import 'package:trial_app/Models/user_model.dart';
import 'package:trial_app/Controllers/profile_controller.dart';
import 'package:trial_app/Controllers/auth_controller.dart';
import 'package:trial_app/Services/session_service.dart';
import 'package:trial_app/Screens/login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trial_app/Services/wishlist_service.dart';
import 'package:trial_app/Controllers/giveaway_controller.dart';
import 'package:trial_app/Models/giveaway_model.dart';
import 'package:trial_app/Screens/games_detail_screen.dart';
import 'package:trial_app/Services/event_service.dart';
import 'package:trial_app/Controllers/event.model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:trial_app/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  final ValueChanged<UserModel>? onUserUpdated;
  const ProfileScreen({super.key, required this.user, this.onUserUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profile = ProfileController();
  final _auth = AuthController();
  final _uname = TextEditingController();
  final _email = TextEditingController();
  final _photoUrl = TextEditingController();
  bool _saving = false;
  bool _isEditing = false; // Mode edit/view
  final _picker = ImagePicker();
  final _wishlist = WishlistService();
  final _giveawayController = GiveawayController();
  final _eventService = EventService();

  @override
  void initState() {
    super.initState();
    
    _uname.text = widget.user.username;
    _email.text = widget.user.email;
    if (widget.user.photoUrl != null && widget.user.photoUrl!.isNotEmpty) {
      final bust = DateTime.now().millisecondsSinceEpoch;
      _photoUrl.text = '${widget.user.photoUrl}?v=$bust';
    } else {
      _photoUrl.text = '';
    }
  }

  void _toggleEditMode() {
    if (_isEditing) {
      // Cancel edit - reset values
      _uname.text = widget.user.username;
      _email.text = widget.user.email;
      if (widget.user.photoUrl != null && widget.user.photoUrl!.isNotEmpty) {
        final bust = DateTime.now().millisecondsSinceEpoch;
        _photoUrl.text = '${widget.user.photoUrl}?v=$bust';
      } else {
        _photoUrl.text = '';
      }
    }
    setState(() => _isEditing = !_isEditing);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final newUsername = _uname.text.trim();
      final newEmail = _email.text.trim();
      final newPhotoUrl = _photoUrl.text.trim().isEmpty ? null : _photoUrl.text.trim();

      await _profile.updateProfile(
       widget.user.id,
        username: newUsername == widget.user.username ? null : newUsername,
        email: newEmail == widget.user.email ? null : newEmail,
        photoUrl: newPhotoUrl == widget.user.photoUrl ? null : newPhotoUrl,
      );

      final updated = UserModel(
        id: widget.user.id,
        username: newUsername,
        email: newEmail,
        passwordHash: widget.user.passwordHash,
        photoUrl: newPhotoUrl ?? widget.user.photoUrl,
      );

      await SessionService().saveUser(updated);
      widget.onUserUpdated?.call(updated);

      if (!mounted) return;
      setState(() => _isEditing = false); // Exit edit mode after save
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppTheme.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal update profile')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    try {
      setState(() => _saving = true);
      final file = File(picked.path);
      final url = await _profile.uploadPhoto(widget.user.id, file);
      if (url != null) {
        final bust = DateTime.now().millisecondsSinceEpoch;
        _photoUrl.text = '$url?v=$bust';
        // Fetch profile terbaru dari DB agar paling update
        final fresh = await _profile.getProfile(widget.user.id);
        if (fresh != null) {
          final updated = UserModel.fromJson(fresh);
          await SessionService().saveUser(updated);
          widget.onUserUpdated?.call(updated);
        }
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto berhasil diunggah')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengunggah foto')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengunggah foto: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Akun?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      await _profile.deleteAccount(widget.user.id);
      await _auth.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _photoUrl.text.trim().isEmpty ? null : _photoUrl.text.trim();
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Header dengan icon edit
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Profile Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isEditing ? Icons.close : Icons.edit,
                            color: _isEditing ? Colors.red : AppTheme.green,
                          ),
                          onPressed: _saving ? null : _toggleEditMode,
                          tooltip: _isEditing ? 'Batal Edit' : 'Edit Profile',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Avatar
                    Stack(
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: ClipOval(
                            child: avatarUrl != null
                                ? Image.network(
                                    avatarUrl,
                                    key: ValueKey(avatarUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade300,
                                        alignment: Alignment.center,
                                        child: Text(
                                          widget.user.username.isNotEmpty 
                                              ? widget.user.username[0].toUpperCase() 
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey.shade300,
                                    alignment: Alignment.center,
                                    child: Text(
                                      widget.user.username.isNotEmpty 
                                          ? widget.user.username[0].toUpperCase() 
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        // Upload button overlay (hanya muncul saat edit mode)
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                onPressed: _saving ? null : _pickAndUpload,
                                tooltip: 'Ubah Foto',
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Username
                    if (_isEditing)
                      TextField(
                        controller: _uname,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person),
                        ),
                        enabled: !_saving,
                      )
                    else
                      _buildInfoRow(
                        icon: Icons.person,
                        label: 'Username',
                        value: widget.user.username,
                      ),
                    const SizedBox(height: 16),
                    // Email
                    if (_isEditing)
                      TextField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        enabled: !_saving,
                        keyboardType: TextInputType.emailAddress,
                      )
                    else
                      _buildInfoRow(
                        icon: Icons.email,
                        label: 'Email',
                        value: widget.user.email,
                      ),
                    // Save button (hanya muncul saat edit mode)
                    if (_isEditing) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(_saving ? 'Menyimpan...' : 'Simpan Perubahan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Delete Account Button
            Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Hapus Akun',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Tindakan ini tidak dapat dibatalkan',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: _confirmDelete,
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text('My Wishlist', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FutureBuilder<List<Giveaway>>(
              future: _fetchWishlistGiveaways(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                final wishlistItems = snapshot.data ?? [];
                if (wishlistItems.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Wishlist kosong', style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: wishlistItems.length,
                  itemBuilder: (context, i) {
                    final g = wishlistItems[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: g.thumbnail != null && g.thumbnail!.isNotEmpty
                            ? Image.network(g.thumbnail!, width: 60, height: 60, fit: BoxFit.cover)
                            : const SizedBox(width: 60, height: 60, child: Icon(Icons.videogame_asset)),
                        title: Text(g.title),
                        subtitle: Text(
                          g.description ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () async {
                            await _wishlist.toggle(widget.user.id, g.id);
                            setState(() {});
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GiveawayDetailPage(giveaway: g),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text('My Tickets', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FutureBuilder<List<EventModel>>(
              future: _eventService.getMyTickets(widget.user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tickets = snapshot.data ?? [];
                if (tickets.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Belum ada tiket event', style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tickets.length,
                  itemBuilder: (context, i) {
                    final e = tickets[i];
                    // Generate unique QR code data untuk tiket ini
                    final qrData = _generateQRData(e, widget.user.id);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.event, size: 40, color: Colors.blue),
                        title: Text(e.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${e.location} • ${e.date.toLocal().toString().split('.')[0]}'),
                            Text('${e.claimedCount}/${e.maxTicket} tickets claimed'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // QR Code button
                            IconButton(
                              icon: const Icon(Icons.qr_code),
                              onPressed: () => _showQRDialog(context, e, qrData),
                              tooltip: 'Lihat QR Code',
                            ),
                            // Map button
                            IconButton(
                              icon: const Icon(Icons.map),
                              onPressed: () async {
                                final url = 'https://www.google.com/maps/search/?api=1&query=${e.latitude},${e.longitude}';
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Giveaway>> _fetchWishlistGiveaways() async {
    try {
      final wishlistIds = await _wishlist.getAll(widget.user.id);
      if (wishlistIds.isEmpty) return [];
      
      final allGiveaways = await _giveawayController.fetchGiveaways();
      return allGiveaways.where((g) => wishlistIds.contains(g.id)).toList();
    } catch (e) {
      return [];
    }
  }

  // Generate unique QR code data untuk tiket
  String _generateQRData(EventModel event, String userId) {
    // Gabungkan event ID, user ID, dan timestamp untuk uniqueness
    final combined = '${event.id}_${userId}_${event.date.millisecondsSinceEpoch}';
    
    // Generate hash menggunakan bcrypt dengan salt tetap untuk konsistensi
    // Format salt bcrypt: $2y$10$ + 22 karakter base64
    // Salt tetap: "TICKETQR2024ABCDEFGHIJKL" (22 chars setelah prefix)
    final fixedSalt = r'$2y$10$TICKETQR2024ABCDEFGHIJKL';
    final hash = BCrypt.hashpw(combined, fixedSalt);
    
    // Ambil bagian hash setelah prefix "$2y$10$" (31 karakter)
    final hashPart = hash.substring(7);
    
    // Format QR data: TICKET|EVENT_ID|USER_ID|HASH
    return 'TICKET|${event.id}|$userId|$hashPart';
  }

  // Helper widget untuk menampilkan info row (view mode)
  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.navyDark, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tampilkan dialog dengan QR code
  void _showQRDialog(BuildContext context, EventModel event, String qrData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Ticket QR Code',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Scan QR code untuk verifikasi tiket',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
