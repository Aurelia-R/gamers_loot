import 'package:flutter/material.dart';
import '../Models/giveaway_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trial_app/Services/currency_service.dart';
import 'package:trial_app/Services/timezone_service.dart';
import 'package:trial_app/Services/wishlist_service.dart';
import 'package:trial_app/theme/app_theme.dart';

class GiveawayDetailPage extends StatefulWidget {
  final Giveaway giveaway;
  final String selectedCurrency;
  final String selectedTimezone;
  final String? userId; // User ID untuk wishlist
  
  const GiveawayDetailPage({
    super.key,
    required this.giveaway,
    this.selectedCurrency = 'USD',
    this.selectedTimezone = 'WIB',
    this.userId, // Optional, kalau tidak ada berarti tidak bisa wishlist
  });

  @override
  State<GiveawayDetailPage> createState() => _GiveawayDetailPageState();
}

class _GiveawayDetailPageState extends State<GiveawayDetailPage> {
  // Service untuk currency conversion
  final currencyService = CurrencyService();
  
  // Service untuk wishlist
  final wishlistService = WishlistService();
  
  // Variabel untuk mengecek apakah game ada di wishlist
  bool isInWishlist = false;
  
  // Fungsi untuk mengecek wishlist saat pertama kali buka halaman
  @override
  void initState() {
    super.initState();
    _checkWishlist();
  }
  
  // Cek apakah game ini ada di wishlist user
  Future<void> _checkWishlist() async {
    // Kalau tidak ada userId, skip
    if (widget.userId == null) return;
    
    // Cek apakah game ada di wishlist
    final exists = await wishlistService.exists(widget.userId!, widget.giveaway.id);
    
    // Update state
    if (mounted) {
      setState(() {
        isInWishlist = exists;
      });
    }
  }
  
  // Fungsi untuk toggle wishlist (tambah/hapus)
  Future<void> _toggleWishlist() async {
    // Kalau tidak ada userId, tidak bisa wishlist
    if (widget.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login dulu untuk menambah wishlist')),
      );
      return;
    }
    
    // Toggle wishlist (kalau sudah ada, hapus. kalau belum, tambah)
    await wishlistService.toggle(widget.userId!, widget.giveaway.id);
    
    // Cek lagi status wishlist setelah toggle
    final exists = await wishlistService.exists(widget.userId!, widget.giveaway.id);
    
    // Update state
    setState(() {
      isInWishlist = exists;
    });
    
    // Tampilkan pesan
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isInWishlist 
              ? 'Ditambahkan ke wishlist' 
              : 'Dihapus dari wishlist'
          ),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      appBar: AppBar(
        backgroundColor: AppTheme.navyDark,
        title: Text(widget.giveaway.title),
        // Tambahkan wishlist button di AppBar
        actions: [
          // Tombol wishlist (icon heart)
          IconButton(
            icon: Icon(
              // Kalau ada di wishlist, pakai heart penuh (merah)
              // Kalau tidak ada, pakai heart kosong (putih)
              isInWishlist ? Icons.favorite : Icons.favorite_border,
              color: isInWishlist ? Colors.red : AppTheme.white,
            ),
            onPressed: _toggleWishlist,
            tooltip: isInWishlist ? 'Hapus dari wishlist' : 'Tambah ke wishlist',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section - Banner image
            if (widget.giveaway.thumbnail != null && widget.giveaway.thumbnail!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 250,
                child: Image.network(
                  widget.giveaway.thumbnail!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.navyDark,
                      child: const Icon(Icons.image_not_supported, size: 50, color: AppTheme.white),
                    );
                  },
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 250,
                color: AppTheme.navyDark,
                child: const Icon(Icons.videogame_asset, size: 80, color: AppTheme.white),
              ),

            // Title section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.giveaway.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
            ),

            // Description
            if (widget.giveaway.description != null && widget.giveaway.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  widget.giveaway.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // About section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'About Game',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Game', widget.giveaway.title),
                        const SizedBox(height: 8),
                        if (widget.giveaway.platform != null)
                          _buildInfoRow('Platform', widget.giveaway.platform!),
                        const SizedBox(height: 8),
                        if (widget.giveaway.publishedDate != null)
                          _buildInfoRow(
                            'Published',
                            TimezoneService.convertEndDate(widget.giveaway.publishedDate, widget.selectedTimezone) ?? widget.giveaway.publishedDate!,
                          ),
                      ],
                    ),
                  ),
                  // Right column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.giveaway.worth != null && widget.giveaway.worth!.isNotEmpty)
                          FutureBuilder<String?>(
                            future: currencyService.convertPrice(widget.giveaway.worth, widget.selectedCurrency),
                            builder: (context, snap) {
                              return _buildPriceRow(snap.data ?? widget.giveaway.worth ?? '-');
                            },
                          ),
                        const SizedBox(height: 8),
                        if (widget.giveaway.endDate != null)
                          _buildInfoRow(
                            'End Date',
                            TimezoneService.convertEndDate(widget.giveaway.endDate, widget.selectedTimezone) ?? widget.giveaway.endDate!,
                          ),
                        const SizedBox(height: 8),
                        if (widget.giveaway.users != null)
                          _buildInfoRow('Claimed', '${widget.giveaway.users} users'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // Get the Game button (besar)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (widget.giveaway.openGiveawayUrl == null) return;
                        final raw = widget.giveaway.openGiveawayUrl!.trim();
                        final uri = Uri.tryParse(raw.startsWith('http') ? raw : 'https://$raw');
                        if (uri == null) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invalid URL')),
                          );
                          return;
                        }
                        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                        if (!ok && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open link')),
                          );
                        }
                      },
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Get the Game'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green,
                        foregroundColor: AppTheme.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Share button (kecil, square)
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // Share functionality bisa ditambahkan nanti
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share feature coming soon')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green,
                        foregroundColor: AppTheme.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.share),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Helper method untuk membuat info row
  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.white,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // Helper method untuk membuat price row (dicoret + FREE)
  Widget _buildPriceRow(String price) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Worth',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              price,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.white.withOpacity(0.5),
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'FREE',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
