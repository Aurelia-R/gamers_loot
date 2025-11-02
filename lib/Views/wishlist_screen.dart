import 'package:flutter/material.dart';
import 'package:trial_app/Models/user_model.dart';
import 'package:trial_app/Models/giveaway_model.dart';
import 'package:trial_app/Services/wishlist_service.dart';
import 'package:trial_app/Controllers/giveaway_controller.dart';
import 'package:trial_app/Views/games_detail_screen.dart';
import 'package:trial_app/theme/app_theme.dart';

class WishlistScreen extends StatefulWidget {
  final UserModel user;
  const WishlistScreen({super.key, required this.user});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final _wishlist = WishlistService();
  final _giveawayController = GiveawayController();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      appBar: AppBar(
        backgroundColor: AppTheme.navyDark,
        title: const Text('My Wishlist'),
        foregroundColor: AppTheme.white,
      ),
      body: FutureBuilder<List<Giveaway>>(
        future: _fetchWishlistGiveaways(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.green),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: AppTheme.white),
              ),
            );
          }
          final wishlistItems = snapshot.data ?? [];
          if (wishlistItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Wishlist kosong',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tambahkan game ke wishlist untuk melihatnya di sini',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.white.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: wishlistItems.length,
            itemBuilder: (context, i) {
              final g = wishlistItems[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: g.thumbnail != null && g.thumbnail!.isNotEmpty
                        ? Image.network(
                            g.thumbnail!,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 70,
                                height: 70,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.videogame_asset),
                              );
                            },
                          )
                        : Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.videogame_asset),
                          ),
                  ),
                  title: Text(
                    g.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    g.description ?? '',
                    maxLines: 2,
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
                        builder: (_) => GiveawayDetailPage(
                          giveaway: g,
                          userId: widget.user.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

