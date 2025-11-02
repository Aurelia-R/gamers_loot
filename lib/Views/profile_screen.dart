import 'package:flutter/material.dart';
import 'dart:io';
import 'package:trial_app/Models/user_model.dart';
import 'package:trial_app/Controllers/profile_controller.dart';
import 'package:trial_app/Controllers/auth_controller.dart';
import 'package:trial_app/Services/session_service.dart';
import 'package:trial_app/Views/login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trial_app/theme/app_theme.dart';
import 'package:trial_app/Views/wishlist_screen.dart';
import 'package:trial_app/Views/tickets_screen.dart';

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
  bool _isEditing = false;
  final _picker = ImagePicker();

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
      setState(() => _isEditing = false);
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
      backgroundColor: AppTheme.navyDark,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.navyDark,
                    AppTheme.navyDark.withOpacity(0.8),
                  ],
                ),
              ),
              child: Row(
                children: [

                  Stack(
          children: [
            SizedBox(
                        width: 70,
                        height: 70,
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
                                          fontSize: 28,
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
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                        ),
                      ),
              ),
            ),

                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                              onPressed: _saving ? null : _pickAndUpload,
                              tooltip: 'Ubah Foto',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                        Text(
                          widget.user.username,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.user.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.white.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: Icon(
                      _isEditing ? Icons.close : Icons.edit,
                      color: _isEditing ? Colors.red : AppTheme.white,
                    ),
                    onPressed: _saving ? null : _toggleEditMode,
                    tooltip: _isEditing ? 'Batal Edit' : 'Edit Profile',
                ),
              ],
            ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
              children: [

                      if (_isEditing)
                        TextField(
                          controller: _uname,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person, size: 20),
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          enabled: !_saving,
                        )
                      else
                        _buildCompactInfoRow(
                          icon: Icons.person,
                          label: 'Username',
                          value: widget.user.username,
                        ),
                      const SizedBox(height: 12),

                      if (_isEditing)
                        TextField(
                          controller: _email,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email, size: 20),
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          enabled: !_saving,
                          keyboardType: TextInputType.emailAddress,
                        )
                      else
                        _buildCompactInfoRow(
                          icon: Icons.email,
                          label: 'Email',
                          value: widget.user.email,
                        ),

                      if (_isEditing) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save, size: 18),
                            label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [

                  _buildCompactMenuCard(
                    icon: Icons.favorite,
                    iconColor: Colors.red,
                    title: 'My Wishlist',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                          builder: (_) => WishlistScreen(user: widget.user),
                            ),
                          );
                        },
                      ),
                  const SizedBox(height: 8),

                  _buildCompactMenuCard(
                    icon: Icons.event,
                    iconColor: Colors.blue,
                    title: 'My Tickets',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TicketsScreen(user: widget.user),
                        ),
                );
              },
            ),
                  const SizedBox(height: 8),

                  _buildCompactMenuCard(
                    icon: Icons.comment,
                    iconColor: AppTheme.green,
                    title: 'Kesan dan Pesan',
                    onTap: () => _showFeedbackDialog(),
                  ),
            const SizedBox(height: 16),

                  TextButton.icon(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_forever, size: 18),
                    label: const Text(
                      'Hapus Akun',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
            const SizedBox(height: 16),
                ],
              ),
                            ),
                          ],
                        ),
                      ),
                    );
  }

  Widget _buildCompactMenuCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildCompactInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.navyDark, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.green,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.comment, color: Colors.white),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Kesan dan Pesan',
                        style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

              Text(
                        'Mata Kuliah Pemrograman Aplikasi Mobile',
                style: TextStyle(
                  fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      

                      Row(
                        children: [
                          Icon(Icons.thumb_up, color: AppTheme.green, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Kesan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
              Container(
                        width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Text(
                          'Mata kuliah Pemrograman Aplikasi Mobile memberikan pengalaman yang sangat berharga dalam pembelajaran pengembangan aplikasi mobile. Dengan menggunakan Flutter, saya dapat memahami konsep multiplatform development yang memungkinkan pembuatan aplikasi untuk Android dan iOS secara bersamaan. Materi yang disampaikan sangat komprehensif, mulai dari dasar-dasar Flutter, state management, hingga integrasi dengan database dan API. Praktik langsung dalam membuat aplikasi memberikan pemahaman yang lebih mendalam dibandingkan hanya teori saja. Dosen yang mengajar sangat membantu dan sabar dalam menjelaskan setiap konsep yang sulit dipahami.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                      const SizedBox(height: 24),
                      

                      Row(
                        children: [
                          Icon(Icons.message, color: AppTheme.green, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Pesan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Text(
                          'Kedepannya, saya berharap mata kuliah ini dapat terus dikembangkan dengan menambahkan materi tentang deployment aplikasi ke Play Store dan App Store, serta best practices dalam pengembangan aplikasi mobile yang scalable. Semoga juga dapat ditambahkan lebih banyak praktik tentang integrasi dengan berbagai API dan teknologi terkini seperti AI/ML integration dalam aplikasi mobile. Terima kasih atas pembelajaran yang sangat bermanfaat ini!',
                style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Tutup'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
