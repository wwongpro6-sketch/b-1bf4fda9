import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Pastikan package ini ada di pubspec.yaml
// import 'package:font_awesome_flutter/font_awesome_flutter.dart'; 
import 'manage_server.dart';
import 'wifi_internal.dart';
import 'wifi_external.dart';
import 'ddos_panel.dart';
import 'nik_check.dart';
import 'tiktok_page.dart';
import 'instagram_page.dart';
import 'qr_gen.dart';
import 'domain_page.dart';
import 'spam_ngl.dart';
import 'phone_lookup_page.dart'; 
import 'music_player_page.dart';
import 'report_telegram_page.dart'; // --- NEW: IMPORT TELEGRAM REPORT PAGE ---

class ToolsPage extends StatefulWidget {
  final String sessionKey;
  final String userRole;
  final List<Map<String, dynamic>> listDoos;

  const ToolsPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
    required this.listDoos,
  });

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;
  
  // Controller untuk efek RGB
  late AnimationController _rgbController;
  late Animation<Color?> _colorAnimation;

  // --- TEMA RGB BLUE NEON ---
  final Color bgBlack = const Color(0xFF050505);
  final Color cardBlack = const Color(0xFF0A0A0A);
  
  // Warna Utama (Biru Neon)
  final Color neonBlue = const Color(0xFF00E5FF); 
  final Color neonCyan = const Color(0xFF00BCD4);
  final Color neonPurple = const Color(0xFF7C4DFF);

  @override
  void initState() {
    super.initState();
    
    // Controller untuk animasi background bergerak
    _bgController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat(reverse: true);

    // Controller untuk efek warna RGB Berubah-ubah
    _rgbController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _colorAnimation = TweenSequence<Color?>(
      [
        TweenSequenceItem(
          weight: 1.0,
          tween: ColorTween(begin: neonBlue, end: neonCyan),
        ),
        TweenSequenceItem(
          weight: 1.0,
          tween: ColorTween(begin: neonCyan, end: neonPurple),
        ),
        TweenSequenceItem(
          weight: 1.0,
          tween: ColorTween(begin: neonPurple, end: neonBlue),
        ),
      ],
    ).animate(_rgbController);

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: Curves.easeOutCubic,
      ),
    );

    _cardController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _rgbController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      body: Stack(
        children: [
          // 1. Animated RGB Background
          _buildAnimatedRGBBackground(),

          // 2. Glass Overlay (untuk meredam warna agar konten terbaca)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: bgBlack.withOpacity(0.6),
              ),
            ),
          ),

          // 3. Konten Utama
          SafeArea(
            child: Column(
              children: [
                _buildNewHeader(),
                Expanded(
                  child: _buildToolCategories(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedRGBBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Stack(
          children: [
            // Bola RGB 1 (Gerak Kiri Atas)
            Positioned(
              top: -100 + (_bgController.value * 50),
              left: -50 + (_bgController.value * 30),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      neonBlue.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bola RGB 2 (Gerak Kanan Bawah)
            Positioned(
              bottom: -100 + (_bgController.value * -50),
              right: -50 + (_bgController.value * -30),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      neonPurple.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNewHeader() {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              // Logo Box dengan Efek RGB Border
              Container(
                padding: const EdgeInsets.all(2), // Border width
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      _colorAnimation.value ?? neonBlue, 
                      neonPurple
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_colorAnimation.value ?? neonBlue).withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black, // Inner box black
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.grid_view_rounded,
                    color: _colorAnimation.value,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tools Gateway",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                        letterSpacing: 1,
                        shadows: [
                          Shadow(
                            color: (_colorAnimation.value ?? neonBlue).withOpacity(0.8),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "Select your weapon",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'ShareTechMono',
                      ),
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (_colorAnimation.value ?? neonBlue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (_colorAnimation.value ?? neonBlue).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  widget.userRole.toUpperCase(),
                  style: TextStyle(
                    color: _colorAnimation.value,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolCategories() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _cardAnimation.value) * 50),
          child: Opacity(
            opacity: _cardAnimation.value,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _buildNewToolCard(0),
                const SizedBox(height: 15),
                _buildNewToolCard(1),
                const SizedBox(height: 15),
                _buildNewToolCard(2),
                const SizedBox(height: 15),
                _buildNewToolCard(3),
                const SizedBox(height: 15),
                _buildNewToolCard(4),
                const SizedBox(height: 15),
                _buildNewToolCard(5), // --- Quick Access (Modified) ---
                const SizedBox(height: 15),
                _buildNewToolCard(6), 
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewToolCard(int index) {
    // Definisi data tools dengan warna Biru/Cyan dominan
    final List<Map<String, dynamic>> tools = [
      {
        "icon": Icons.flash_on_rounded,
        "title": "DDoS Panel",
        "subtitle": "L4/L7 Stress Test Attack",
        "gradient": [const Color(0xFF00E5FF), const Color(0xFF2979FF)], // Cyan to Blue
        "onTap": () => _showDDoSTools(context),
      },
      {
        "icon": Icons.wifi_tethering,
        "title": "Network Tools",
        "subtitle": "WiFi Killer & Spam NGL",
        "gradient": [const Color(0xFF2962FF), const Color(0xFF6200EA)], // Blue to Deep Purple
        "onTap": () => _showNetworkTools(context),
      },
      {
        "icon": Icons.travel_explore,
        "title": "OSINT Tools",
        "subtitle": "NIK Checker, Domain, IP",
        "gradient": [const Color(0xFF00BFA5), const Color(0xFF00E676)], // Teal to Green
        "onTap": () => _showOSINTTools(context),
      },
      {
        "icon": Icons.download_rounded,
        "title": "Media Downloader",
        "subtitle": "TikTok & Instagram No Watermark",
        "gradient": [const Color(0xFF651FFF), const Color(0xFFE040FB)], // Purple to Pink
        "onTap": () => _showDownloaderTools(context),
      },
      {
        "icon": Icons.auto_fix_high,
        "title": "Generator Tools",
        "subtitle": "QR Generator & Utilities",
        "gradient": [const Color(0xFFFF9100), const Color(0xFFFF3D00)], // Orange
        "onTap": () => _showUtilityTools(context),
      },
      // --- MODIFIED: Quick Access ---
      {
        "icon": Icons.rocket_launch_rounded,
        "title": "Quick Access",
        "subtitle": "Telegram Report & More",
        "gradient": [const Color(0xFF76FF03), const Color(0xFF64DD17)], // Lime
        "onTap": () => _showQuickAccess(context), // Sekarang membuka Modal
      },
      {
        "icon": Icons.music_note_rounded,
        "title": "Music Player",
        "subtitle": "Stream & Background Play",
        "gradient": [const Color(0xFFFF4081), const Color(0xFFD500F9)], // Pink to Purple
        "onTap": () {
           Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MusicPlayerPage()),
          );
        },
      },
    ];

    final tool = tools[index];
    final List<Color> gradientColors = tool["gradient"];

    return GestureDetector(
      onTap: tool["onTap"],
      child: AnimatedBuilder(
        animation: _colorAnimation, // Efek border berdenyut
        builder: (context, child) {
          return Container(
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.black.withOpacity(0.6), // Transparan gelap
              border: Border.all(
                color: gradientColors[0].withOpacity(0.5), // Border warna sesuai tema card
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Glass Effect
                child: Stack(
                  children: [
                    // Gradient Swipe Effect (Background tipis)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              gradientColors[0].withOpacity(0.2),
                              Colors.transparent
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      child: Row(
                        children: [
                          // Icon Box
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: gradientColors[0].withOpacity(0.4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(tool["icon"], color: Colors.white, size: 26),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  tool["title"],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Orbitron',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tool["subtitle"],
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: gradientColors[0].withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: gradientColors[1],
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- MODAL SHEETS ---

  Widget _buildNewModalSheet(
      BuildContext context,
      String title,
      IconData icon,
      List<Widget> options,
      ) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return ClipRRect( // Clip untuk border radius
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                border: Border.all(
                  color: (_colorAnimation.value ?? neonBlue).withOpacity(0.5),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (_colorAnimation.value ?? neonBlue).withOpacity(0.3),
                          Colors.transparent
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: _colorAnimation.value, size: 30),
                        const SizedBox(width: 16),
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: (_colorAnimation.value ?? neonBlue).withOpacity(0.8),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Options List
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListView(children: options),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: neonBlue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: neonBlue.withOpacity(0.5)),
          ),
          child: Icon(icon, color: neonCyan),
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
        onTap: onTap,
      ),
    );
  }

  // --- ACTIONS ---

  void _showDDoSTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildNewModalSheet(
        context,
        "DDoS Tools",
        Icons.flash_on,
        [
          _buildModalOption(
            icon: Icons.flash_on,
            label: "Attack Panel",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttackPanel(
                    sessionKey: widget.sessionKey,
                    listDoos: widget.listDoos,
                  ),
                ),
              );
            },
          ),
          _buildModalOption(
            icon: Icons.dns,
            label: "Manage Server",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManageServerPage(keyToken: widget.sessionKey),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showNetworkTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildNewModalSheet(
        context,
        "Network Tools",
        Icons.wifi,
        [
          _buildModalOption(
            icon: Icons.newspaper_outlined,
            label: "Spam NGL",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NglPage()),
              );
            },
          ),
          _buildModalOption(
            icon: Icons.wifi_off,
            label: "WiFi Killer (Internal)",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WifiKillerPage()),
              );
            },
          ),
          if (widget.userRole == "vip" || widget.userRole == "owner")
            _buildModalOption(
              icon: Icons.router,
              label: "WiFi Killer (External)",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WifiInternalPage(sessionKey: widget.sessionKey),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showOSINTTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildNewModalSheet(
        context,
        "OSINT Tools",
        Icons.search,
        [
          _buildModalOption(
            icon: Icons.badge,
            label: "NIK Detail",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NikCheckerPage()),
              );
            },
          ),
          _buildModalOption(
            icon: Icons.domain,
            label: "Domain OSINT",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DomainOsintPage()),
              );
            },
          ),
          _buildModalOption(
            icon: Icons.person_search,
            label: "Phone Lookup",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PhoneLookupPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDownloaderTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildNewModalSheet(
        context,
        "Media Downloader",
        Icons.download,
        [
          _buildModalOption(
            icon: Icons.video_library,
            label: "TikTok Downloader",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TiktokDownloaderPage()),
              );
            },
          ),
          _buildModalOption(
            icon: Icons.camera_alt,
            label: "Instagram Downloader",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InstagramDownloaderPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showUtilityTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildNewModalSheet(
        context,
        "Utility Tools",
        Icons.build,
        [
          _buildModalOption(
            icon: Icons.qr_code,
            label: "QR Generator",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrGeneratorPage()),
              );
            },
          ),
          _buildModalOption(
            icon: Icons.security,
            label: "IP Scanner",
            onTap: () => _showComingSoon(context),
          ),
        ],
      ),
    );
  }

  // --- MODIFIED: Quick Access with Modal Sheet ---
  void _showQuickAccess(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildNewModalSheet(
        context,
        "Quick Access",
        Icons.rocket_launch,
        [
          // --- NEW: Telegram Report Item ---
          _buildModalOption(
            icon: Icons.telegram,
            label: "Telegram Report",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TelegramReportPage()),
              );
            },
          ),
          // Tambahkan item lain jika ada
          _buildModalOption(
            icon: Icons.bookmark,
            label: "Saved Server",
            onTap: () => _showComingSoon(context),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.hourglass_top, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Feature Coming Soon!',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: neonBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}