import 'package:flutter/material.dart';
import '../Models/giveaway_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trial_app/Services/currency_service.dart';
import 'package:trial_app/Services/timezone_service.dart';
import 'package:trial_app/Services/wishlist_service.dart';
import 'package:trial_app/Services/notification_service.dart';
import 'package:trial_app/theme/app_theme.dart';

class GiveawayDetailPage extends StatefulWidget {
  final Giveaway giveaway;
  final String selectedCurrency;
  final String selectedTimezone;
  final String? userId;
  
  const GiveawayDetailPage({
    super.key,
    required this.giveaway,
    this.selectedCurrency = 'USD',
    this.selectedTimezone = 'WIB',
    this.userId,
  });

  @override
  State<GiveawayDetailPage> createState() => _GiveawayDetailPageState();
}

class _GiveawayDetailPageState extends State<GiveawayDetailPage> {

  final currencyService = CurrencyService();
  

  final wishlistService = WishlistService();
  

  bool isInWishlist = false;
  

  @override
  void initState() {
    super.initState();
    _checkWishlist();
  }
  

  Future<void> _checkWishlist() async {

    if (widget.userId == null) return;
    

    final exists = await wishlistService.exists(widget.userId!, widget.giveaway.id);
    

    if (mounted) {
      setState(() {
        isInWishlist = exists;
      });
      

      if (exists) {
        _scheduleWishlistNotification();
      }
    }
  }
  

  Future<void> _toggleWishlist() async {

    if (widget.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login dulu untuk menambah wishlist')),
      );
      return;
    }
    

    await wishlistService.toggle(widget.userId!, widget.giveaway.id);
    

    final exists = await wishlistService.exists(widget.userId!, widget.giveaway.id);
    

    setState(() {
      isInWishlist = exists;
    });
    

    if (exists && widget.giveaway.endDate != null) {
      _scheduleWishlistNotification();
    } 

    else if (!exists) {
      NotificationService.cancelWishlistNotification(widget.giveaway.id);
    }
    

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
  

  void _scheduleWishlistNotification() {

    if (widget.giveaway.endDate == null) return;
    
    try {

      final endDate = DateTime.parse(widget.giveaway.endDate!);
      

      final notificationDate = endDate.subtract(const Duration(days: 1));
      

      if (notificationDate.isAfter(DateTime.now())) {
        NotificationService.scheduleWishlistGameNotification(
          gameId: widget.giveaway.id,
          gameTitle: widget.giveaway.title,
          scheduledDate: notificationDate,
        );
      }
    } catch (e) {

    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      appBar: AppBar(
        backgroundColor: AppTheme.navyDark,
        title: Text(widget.giveaway.title),

        actions: [

          IconButton(
            icon: Icon(

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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [

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

                  SizedBox(
                    width: 56,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {

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
