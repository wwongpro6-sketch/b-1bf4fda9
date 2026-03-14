import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'buy_account_page.dart'; // Import halaman Buy Account

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // --- Palette Warna "Furina / Hydro Archon Theme" ---
  // Dominasi Biru Laut, Cyan, dan Deep Navy
  final Color bgBlack = const Color(0xFF020610); // Very Dark Navy (Almost Black)
  final Color bgDark = const Color(0xFF0A1535);  // Deep Ocean Blue
  final Color primaryBlue = const Color(0xFF2979FF); // Royal Blue (Furina's Coat)
  final Color primaryCyan = const Color(0xFF00E5FF); // Hydro Cyan (Vision/Highlights)
  final Color textWhite = const Color(0xFFFFFFFF);
  final Color textGrey = const Color(0xFFCFD8DC);

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset("assets/videos/landing.mp4")
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      });

    _fadeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Slide animation adjusted to come from bottom since layout changed
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      body: Stack(
        children: [
          // 1. Background pattern (Oceanic depth)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    bgDark,      // Lighter blue at top
                    bgBlack,     // Darker at bottom
                    Colors.black,
                  ],
                ),
              ),
              child: CustomPaint(
                painter: BackgroundPattern(),
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // --- SECTION 1: VIDEO CARD (Text "Miyako" Inside) ---
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      height: 300, // Slightly taller to fit text
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        // Border glow effect (Hydro Cyan)
                        border: Border.all(color: primaryCyan.withOpacity(0.3), width: 1),
                        boxShadow: [
                           BoxShadow(
                             color: primaryBlue.withOpacity(0.2),
                             blurRadius: 30,
                             spreadRadius: 5,
                           ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            // 1.1 Video Layer
                            _controller.value.isInitialized
                                ? SizedBox.expand(
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width: _controller.value.size.width,
                                        height: _controller.value.size.height,
                                        child: VideoPlayer(_controller),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFF050C1F),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),

                            // 1.2 Gradient Overlay (To make text readable)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.6), // Darken bottom for text
                                      Colors.black.withOpacity(0.9),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // 1.3 CONTENT INSIDE VIDEO (Miyako Text + Badge)
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Title: Miyako
                                  Text(
                                    "Demonix Reaper",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: textWhite,
                                      fontSize: 36,
                                      fontFamily: 'Courier', 
                                      fontWeight: FontWeight.w900,
                                      shadows: [
                                        Shadow(
                                          color: primaryBlue.withOpacity(0.8),
                                          blurRadius: 20,
                                          offset: const Offset(0, 0),
                                        ),
                                        Shadow(
                                          color: primaryCyan.withOpacity(0.8),
                                          blurRadius: 10,
                                          offset: const Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 12),

                                  // Badge Pill: @mizukisnji
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(30),
                                          border: Border.all(
                                            color: primaryCyan.withOpacity(0.6),
                                            width: 1.0,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryBlue.withOpacity(0.3),
                                              blurRadius: 15,
                                            )
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.verified, color: primaryCyan, size: 16),
                                            const SizedBox(width: 8),
                                            Text(
                                              "@PdlPdf",
                                              style: TextStyle(
                                                color: textWhite,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- SECTION 2: BUTTONS (Moved Below Video) ---
                  SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Button 1: LOGIN ACCOUNT (Gradient Blue)
                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [primaryBlue, primaryCyan], // Blue -> Cyan
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, "/login");
                              },
                              child: Text(
                                "LOGIN ACCOUNT",
                                style: TextStyle(
                                  color: textWhite,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                            
                          const SizedBox(height: 16),

                          // Button 2: BUY ACCESS (Outlined Blue) -> Modified to open BuyAccountPage
                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.transparent,
                              border: Border.all(color: primaryCyan, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryCyan.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: TextButton.icon(
                              onPressed: () {
                                // PERUBAHAN DI SINI: Navigasi ke BuyAccountPage
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const BuyAccountPage()),
                                );
                              },
                              icon: Icon(Icons.shopping_cart_outlined, color: textWhite, size: 20),
                              label: Text(
                                "BUY ACCESS",
                                style: TextStyle(
                                  color: textWhite,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- SECTION 3: FOOTER ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF081025).withOpacity(0.8), 
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                       boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                        )
                      ]
                    ),
                    child: Column(
                      children: [
                        Text(
                          "CONNECT WITH US",
                          style: TextStyle(
                            color: primaryCyan, 
                            fontSize: 12,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialCircle(
                              icon: FontAwesomeIcons.telegram,
                              url: "https://t.me/PdlPdf",
                              color: const Color(0xFF0088CC), 
                            ),
                            const SizedBox(width: 20),
                            _buildSocialCircle(
                              icon: FontAwesomeIcons.tiktok,
                              url: "https://tiktok.com/hokokokoko7",
                              color: textWhite, 
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Divider(color: Colors.white.withOpacity(0.1), height: 1),
                        const SizedBox(height: 16),
                        Text(
                          "@2026 Demonix Projects",
                          style: TextStyle(
                            color: textGrey.withOpacity(0.5),
                            fontSize: 10,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialCircle({required IconData icon, required String url, required Color color}) {
    return GestureDetector(
      onTap: () => _openUrl(url),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: FaIcon(
            icon,
            color: color,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class BackgroundPattern extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Ubah warna dot pattern agar sesuai tema (Cool Blue)
    final paint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    const dotSize = 2.0;
    const spacing = 30.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}