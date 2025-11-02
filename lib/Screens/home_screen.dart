import 'package:flutter/material.dart';
import 'package:trial_app/Models/user_model.dart';
import 'package:trial_app/Controllers/auth_controller.dart';
import 'package:trial_app/Screens/login_screen.dart';
import 'package:trial_app/Screens/profile_screen.dart';
import 'package:trial_app/Controllers/giveaway_controller.dart';
import 'package:trial_app/Models/giveaway_model.dart';
import 'package:trial_app/Screens/games_detail_screen.dart';
import 'package:trial_app/Services/wishlist_service.dart';
import 'package:trial_app/Services/currency_service.dart';
import 'package:trial_app/theme/app_theme.dart';
import 'package:trial_app/Screens/event_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variabel
  final _auth = AuthController();
  final Future<List<Giveaway>> _futureGiveaways = GiveawayController().fetchGiveaways();
  final _wishlist = WishlistService();
  final _currencyService = CurrencyService();
  int _currentIndex = 0;
  
  // Search dan filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedPlatform;
  
  // Currency
  String _selectedCurrency = 'USD';
  final List<String> _currencies = ['USD', 'IDR', 'GBP', 'EUR', 'JPY'];
  
  // Timezone
  String _selectedTimezone = 'WIB';
  final List<String> _timezones = ['WIB', 'WITA', 'WIT', 'London', 'Amerika'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildGiveawayPage(),
      EventScreen(userId: widget.user.id),
      ProfileScreen(
        user: widget.user,
        onUserUpdated: (u) => setState(() => widget.user
          ..username = u.username
          ..email = u.email
          ..photoUrl = u.photoUrl),
      ),
    ];

    String getAppBarTitle() {
      switch (_currentIndex) {
        case 0:
          return '';
        case 1:
          return 'Free Event';
        case 2:
          return 'Profile';
        default:
          return '';
      }
    }

    return Scaffold(
      appBar: _currentIndex == 0
          ? null 
          : AppBar(
              title: Text(getAppBarTitle()),
              actions: [
                if (_currentIndex == 2)
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => _showLogoutDialog(context),
                    tooltip: 'Logout',
                  ),
              ],
            ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.videogame_asset), label: 'Free Games'),
          BottomNavigationBarItem(icon: Icon(Icons.local_activity), label: 'Free Event'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // Dapatkan semua platform unik (pisahkan yang ada koma)
  List<String> _getPlatforms(List<Giveaway> giveaways) {
    final platforms = <String>{};
    for (var g in giveaways) {
      if (g.platform != null && g.platform!.isNotEmpty) {
        // Pisahkan platform yang dipisahkan koma
        final platformList = g.platform!.split(',');
        for (var platform in platformList) {
          // Trim whitespace dan tambahkan jika tidak kosong
          final trimmed = platform.trim();
          if (trimmed.isNotEmpty) {
            platforms.add(trimmed);
          }
        }
      }
    }
    return platforms.toList()..sort();
  }

  // Filter giveaways berdasarkan search dan platform
  List<Giveaway> _filterGiveaways(List<Giveaway> giveaways) {
    var filtered = giveaways;

    // Filter berdasarkan search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((g) {
        final title = g.title.toLowerCase();
        final desc = (g.description ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || desc.contains(query);
      }).toList();
    }

    // Filter berdasarkan platform
    if (_selectedPlatform != null && _selectedPlatform!.isNotEmpty) {
      filtered = filtered.where((g) {
        if (g.platform == null || g.platform!.isEmpty) return false;
        // Split platform yang ada koma dan cek apakah ada yang match
        final platformList = g.platform!.split(',').map((p) => p.trim().toLowerCase()).toList();
        return platformList.contains(_selectedPlatform!.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  Widget _buildGiveawayPage() {
    return FutureBuilder<List<Giveaway>>(
        future: _futureGiveaways,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.navyDark,
                    AppTheme.navyDark.withOpacity(0.9),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.green),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Memuat giveaway...',
                      style: TextStyle(
                        color: AppTheme.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.navyDark,
                    AppTheme.navyDark.withOpacity(0.9),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(
                        color: AppTheme.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          final allGiveaways = snapshot.data ?? const <Giveaway>[];
          
          // Filter giveaways
          final filteredGiveaways = _filterGiveaways(allGiveaways);
          final platforms = _getPlatforms(allGiveaways);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.navyDark,
                  AppTheme.navyDark.withOpacity(0.95),
                  Colors.grey.shade900,
                ],
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header dengan greeting dan logo
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting
                        Text(
                          'Halo, ${widget.user.username}! 👋',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Temukan giveaway game favoritmu',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Search bar dengan card style
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari game giveaway...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: const Icon(Icons.search, color: AppTheme.green),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey.shade600),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ),
                  ),

                  // Filter section dalam card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Filter currency dan timezone
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedCurrency,
                                    decoration: InputDecoration(
                                      labelText: 'Mata Uang',
                                      labelStyle: const TextStyle(fontSize: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      isDense: true,
                                    ),
                                    dropdownColor: Colors.white,
                                    items: _currencies.map((currency) {
                                      return DropdownMenuItem<String>(
                                        value: currency,
                                        child: Text(currency, style: const TextStyle(fontSize: 14)),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _selectedCurrency = value);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedTimezone,
                                    decoration: InputDecoration(
                                      labelText: 'Timezone',
                                      labelStyle: const TextStyle(fontSize: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      isDense: true,
                                    ),
                                    dropdownColor: Colors.white,
                                    items: _timezones.map((timezone) {
                                      return DropdownMenuItem<String>(
                                        value: timezone,
                                        child: Text(timezone, style: const TextStyle(fontSize: 14)),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _selectedTimezone = value);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Filter platform
                            Text(
                              'Platform',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 36,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  // Chip "Semua Platform"
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: const Text('Semua', style: TextStyle(fontSize: 12)),
                                      selected: _selectedPlatform == null,
                                      selectedColor: AppTheme.green.withOpacity(0.2),
                                      checkmarkColor: AppTheme.green,
                                      onSelected: (selected) {
                                        setState(() => _selectedPlatform = null);
                                      },
                                    ),
                                  ),
                                  // Chips untuk setiap platform
                                  ...platforms.map((platform) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: FilterChip(
                                        label: Text(platform, style: const TextStyle(fontSize: 12)),
                                        selected: _selectedPlatform == platform,
                                        selectedColor: AppTheme.green.withOpacity(0.2),
                                        checkmarkColor: AppTheme.green,
                                        onSelected: (selected) {
                                          setState(() => _selectedPlatform = selected ? platform : null);
                                        },
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Results count
                  if (filteredGiveaways.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Text(
                            '${filteredGiveaways.length} game ditemukan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Grid giveaways dengan Wrap untuk menghindari overflow
                  filteredGiveaways.isEmpty
                      ? SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tidak ada giveaway yang ditemukan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Coba ubah filter atau kata kunci pencarian',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.white.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Hitung lebar setiap card (constraints sudah minus padding)
                              final cardWidth = (constraints.maxWidth - 16) / 2; // 16 = spacing antara cards
                              final cardHeight = cardWidth / 0.70; // Disesuaikan untuk menghindari overflow
                              
                              return Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                alignment: WrapAlignment.start,
                                children: filteredGiveaways.map((g) {
                                  return SizedBox(
                                    width: cardWidth,
                                    height: cardHeight,
                                    child: _buildGameCard(g),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 20), // Padding bottom untuk scroll
                ],
              ),
            ),
          );
        },
      );
  }

  // Buat card untuk game di grid
  Widget _buildGameCard(Giveaway g) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GiveawayDetailPage(
                giveaway: g,
                selectedCurrency: _selectedCurrency,
                selectedTimezone: _selectedTimezone,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: g.thumbnail != null && g.thumbnail!.isNotEmpty
                  ? Image.network(
                      g.thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.navyDark,
                                AppTheme.navyDark.withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_not_supported, color: AppTheme.white, size: 40),
                          ),
                        );
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.navyDark,
                            AppTheme.navyDark.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.videogame_asset, size: 50, color: AppTheme.white),
                      ),
                    ),
            ),
            // Gradient overlay untuk readability
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            // Wishlist button di pojok kanan atas
            Positioned(
              top: 8,
              right: 8,
              child: FutureBuilder<bool>(
                future: _wishlist.exists(widget.user.id, g.id),
                builder: (context, snap) {
                  final fav = snap.data == true;
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    elevation: 3,
                    shadowColor: Colors.black.withOpacity(0.3),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () async {
                        await _wishlist.toggle(widget.user.id, g.id);
                        setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          fav ? Icons.favorite : Icons.favorite_border,
                          color: fav ? Colors.red : Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Info overlay di bagian bawah
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      g.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Info tambahan dalam column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Jumlah claimed users
                        if (g.users != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people, size: 14, color: Colors.white.withOpacity(0.9)),
                                const SizedBox(width: 4),
                                Text(
                                  '${g.users}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // FREE badge di bawah claimed users
                        if (g.users != null) const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.green,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (g.worth != null && g.worth!.isNotEmpty)
                                FutureBuilder<String?>(
                                  future: _currencyService.convertPrice(g.worth, _selectedCurrency),
                                  builder: (context, snap) {
                                    if (snap.connectionState == ConnectionState.waiting) {
                                      return const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      );
                                    }
                                    final price = snap.data ?? g.worth!;
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          price,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white.withOpacity(0.7),
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                    );
                                  },
                                ),
                              const Text(
                                'FREE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog konfirmasi logout
  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
