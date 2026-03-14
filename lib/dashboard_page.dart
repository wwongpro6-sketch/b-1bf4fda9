import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

// Custom Imports
import 'bug_sender.dart';
import 'global_sender.dart'; // Added Import for Global Sender
import 'nik_check.dart';
import 'admin_page.dart';
import 'home_page.dart';
import 'custom_bug.dart';
import 'seller_page.dart';
import 'change_password_page.dart';
import 'tools_gateway.dart';
import 'login_page.dart';
import 'anime_home.dart';
import 'PublicChatPage.dart';
import 'komik_home.dart';
import 'AiChatPage.dart';
import 'private_chat.dart';
import 'support.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  // --- ANIMATION CONTROLLERS ---
  late AnimationController _controller;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _animation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  
  late WebSocketChannel channel;

  // --- USER DATA ---
  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;
  String androidId = "unknown";

  int _selectedTabIndex = 0;
  Widget _selectedPage = const Placeholder();

  int onlineUsers = 0;
  int activeConnections = 0;

  // --- SLIDER VARIABLES ---
  final PageController _headerPageController = PageController();
  int _currentHeaderIndex = 0;
  final List<String> _sliderImages = [
    "https://j.top4top.io/p_3650rw72g1.jpg", 
    "https://f.top4top.io/p_3655toh401.jpg", 
  ];

  // --- THEME PALETTE (CYBERPUNK GLASS) ---
  final Color bgBlack = const Color(0xFF050510);
  final Color cardBlack = const Color(0xFF161F30);
  final Color cardGlass = const Color(0xFF161F30).withOpacity(0.6);
  final Color primaryMain = const Color(0xFF536DFE);
  final Color primaryAccent = const Color(0xFF00E5FF);
  final Color neonPurple = const Color(0xFFD500F9);

  final Color textWhite = const Color(0xFFFFFFFF);
  final Color textGrey = const Color(0xFFB0BEC5);

  final String baseUrl = "http://159.195.64.135:4000";

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;
    listDoos = widget.listDoos;
    newsList = widget.news;

    // Initialize Animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _controller.forward();
    _fadeController.forward();

    _selectedPage = _buildNeonDashboard();
    _initAndroidIdAndConnect();
  }

  Future<void> _initAndroidIdAndConnect() async {
    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      androidId = deviceInfo.id;
      _connectToWebSocket();
    } catch (e) {
      print("Init Error: $e");
    }
  }

  void _connectToWebSocket() {
    try {
      channel = WebSocketChannel.connect(Uri.parse(baseUrl));
      channel.sink.add(jsonEncode({
        "type": "validate",
        "key": sessionKey,
        "androidId": androidId,
      }));
      channel.sink.add(jsonEncode({"type": "stats"}));

      channel.stream.listen((event) {
        final data = jsonDecode(event);
        if (data['type'] == 'myInfo') {
          if (data['valid'] == false) {
            if (data['reason'] == 'androidIdMismatch') {
              _handleInvalidSession("Your account has logged on another device.");
            } else if (data['reason'] == 'keyInvalid') {
              _handleInvalidSession("Key is not valid. Please login again.");
            }
          }
        }
        if (data['type'] == 'stats') {
          if (mounted) {
            setState(() {
              onlineUsers = data['onlineUsers'] ?? 0;
              activeConnections = data['activeConnections'] ?? 0;
            });
          }
        }
      }, onError: (err) {
        print("WebSocket Error: $err");
      });
    } catch (e) {
      print("WebSocket Connect Error: $e");
    }
  }

  void _handleInvalidSession(String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: bgBlack.withOpacity(0.9),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.redAccent.withOpacity(0.5))),
          title: const Text("⚠️ Session Expired",
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          content: Text(message, style: TextStyle(color: textWhite)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text("OK", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedTabIndex = index;
      if (index == 0) {
        _selectedPage = _buildNeonDashboard();
      } else if (index == 1) {
        _selectedPage = ToolsPage(
            sessionKey: sessionKey, userRole: role, listDoos: listDoos);
      } else if (index == 2) {
        _selectedPage = const HomeKomikPage();
      } else if (index == 3) {
        _selectedPage = const AiChatPage();
      }
    });
  }

  void _onDrawerItemSelected(int index) {
    setState(() {
      if (index == 5) {
        _selectedPage = SellerPage(keyToken: sessionKey);
      } else if (index == 6) {
        _selectedPage = AdminPage(sessionKey: sessionKey);
      }
    });
  }

  // --- NEW: SENDER TYPE SELECTION SHEET (OWNER ONLY) ---
  void _showSenderTypeSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(top: BorderSide(color: primaryAccent.withOpacity(0.5), width: 1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.orangeAccent, Colors.deepPurpleAccent],
                  ).createShader(bounds),
                  child: const Text(
                    "SENDER NODE SELECTOR",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildChatOption(
                  icon: Icons.public,
                  color: Colors.orangeAccent,
                  title: "Global Sender",
                  subtitle: "Manage public nodes (Owner)",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GlobalSenderPage(
                          sessionKey: sessionKey,
                          username: username,
                          role: role,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildChatOption(
                  icon: Icons.lock_person_rounded,
                  color: primaryAccent,
                  title: "Private Sender",
                  subtitle: "Manage personal session",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BugSenderPage(
                          sessionKey: sessionKey,
                          username: username,
                          role: role,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBugMenuSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(top: BorderSide(color: primaryAccent.withOpacity(0.5), width: 1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.purpleAccent, Colors.redAccent],
                  ).createShader(bounds),
                  child: const Text(
                    "ATTACK MENU SELECTOR",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                _buildChatOption(
                  icon: Icons.bug_report_rounded,
                  color: Colors.cyanAccent,
                  title: "Standard Bug Menu",
                  subtitle: "Open classic attack panel",
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedPage = HomePage(
                        username: username,
                        password: password,
                        listBug: listBug,
                        role: role,
                        expiredDate: expiredDate,
                        sessionKey: sessionKey,
                      );
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildChatOption(
                  icon: Icons.security_rounded,
                  color: Colors.redAccent,
                  title: "Custom Bug (VIP & Owner)",
                  subtitle: "Execute custom payload attack",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => CustomAttackPage(
                          username: username,
                          password: password,
                          sessionKey: sessionKey,
                          listPayload: listBug, 
                          role: role,
                          expiredDate: expiredDate,
                        )
                      )
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChatSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(top: BorderSide(color: primaryAccent.withOpacity(0.3), width: 1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [primaryMain, primaryAccent],
                  ).createShader(bounds),
                  child: const Text(
                    "Global Communication",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildChatOption(
                  icon: Icons.public,
                  color: Colors.cyanAccent,
                  title: "Public Chat",
                  subtitle: "Join the worldwide community",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PublicChatPage(username: username)));
                  },
                ),
                const SizedBox(height: 16),
                _buildChatOption(
                  icon: Icons.lock_outline,
                  color: Colors.pinkAccent,
                  title: "Private Chat",
                  subtitle: "Encrypted direct messaging",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PrivateUserListPage(myUsername: username)));
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatOption({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, spreadRadius: 1),
            ],
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(color: textWhite, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: textGrey, fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: textGrey, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildNeonDashboard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryMain.withOpacity(0.15),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: neonPurple.withOpacity(0.15),
                ),
              ),
            ),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1),
                                ),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.blueAccent.withOpacity(0.1),
                                  child: const Icon(Icons.person, color: Colors.blueAccent),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Welcome back,",
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    username,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(color: Colors.white.withOpacity(0.1), height: 1),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 16, color: Colors.blueAccent.shade200),
                          const SizedBox(width: 10),
                          Text(
                            "Account expires: ",
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                              fontFamily: 'Courier',
                            ),
                          ),
                          Text(
                            expiredDate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white, width: 2), 
                    boxShadow: [
                      BoxShadow(
                        color: primaryMain.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28), 
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _headerPageController,
                          itemCount: _sliderImages.length,
                          onPageChanged: (index) => setState(() => _currentHeaderIndex = index),
                          itemBuilder: (context, index) {
                            return Image.network(
                              _sliderImages[index],
                              fit: BoxFit.cover, // Ensures image covers the slider area nicely
                              width: double.infinity, 
                              height: double.infinity, // Force height match
                              filterQuality: FilterQuality.high, 
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: primaryAccent,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Container(color: bgBlack),
                            );
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, bgBlack.withOpacity(0.9)],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 20,
                          bottom: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5),
                                  ],
                                ),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.verified, color: Colors.blueAccent, size: 16),
                                      const SizedBox(width: 5),
                                      Text(
                                        role.toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Welcome Back, $username",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 2))],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 25,
                          right: 25,
                          child: Row(
                            children: List.generate(
                              _sliderImages.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(left: 6),
                                width: _currentHeaderIndex == index ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentHeaderIndex == index ? primaryAccent : Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: _currentHeaderIndex == index 
                                    ? [BoxShadow(color: primaryAccent.withOpacity(0.5), blurRadius: 8)] 
                                    : [],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                _buildSectionTitle("Support Center", primaryAccent),
                const SizedBox(height: 15),
                
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF512F).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportPage()));
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 30),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Need Help?",
                                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "Contact SupportXTeam for assistance",
                                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Icon(Icons.arrow_forward, color: Color(0xFFDD2476)),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                _buildSectionTitle("Quick Access", neonPurple),
                const SizedBox(height: 15),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildGlassGridCard(
                        icon: FontAwesomeIcons.whatsapp,
                        color1: const Color(0xFF00C9FF),
                        color2: const Color(0xFF92FE9D),
                        title: "WhatsApp",
                        subtitle: "Tools & Bots",
                        onTap: () {
                          // CHANGE: Added role 'vip' to allow access to Custom Bug Menu
                          if (role == 'owner' || role == 'vip') {
                            _showBugMenuSelection();
                          } else {
                            setState(() {
                              _selectedPage = HomePage(
                                username: username,
                                password: password,
                                listBug: listBug,
                                role: role,
                                expiredDate: expiredDate,
                                sessionKey: sessionKey,
                              );
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildGlassGridCard(
                        icon: Icons.send_to_mobile_rounded,
                        color1: const Color(0xFF654ea3),
                        color2: const Color(0xFFeaafc8),
                        title: "Sender",
                        subtitle: "Manage Msg",
                        onTap: () {
                          // CHANGE: Updated Logic for Sender
                          if (role == 'owner') {
                            _showSenderTypeSelection();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BugSenderPage(
                                  sessionKey: sessionKey,
                                  username: username,
                                  role: role,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 15),

                _buildGlassWideCard(
                  icon: FontAwesomeIcons.telegram,
                  accentColor: const Color(0xFF29B6F6),
                  title: "Telegram Channel",
                  subtitle: "Click here to join updates",
                  onTap: () async {
                    final Uri url = Uri.parse('https://t.me/PdlPdf1');
                    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                      throw Exception('Could not launch $url');
                    }
                  },
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: _buildSmallGlassCard(
                        icon: Icons.movie_filter_rounded,
                        color: Colors.orangeAccent,
                        title: "Anime",
                        onTap: () {
                          setState(() {
                            _selectedPage = HomeAnimePage();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildSmallGlassCard(
                        icon: Icons.public,
                        color: primaryAccent,
                        title: "Public",
                        onTap: () => _showChatSelection(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassGridCard({
    required IconData icon,
    required Color color1,
    required Color color2,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E293B).withOpacity(0.8),
              const Color(0xFF0F172A).withOpacity(0.9),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [color1.withOpacity(0.5), color2.withOpacity(0.5)]),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color1, color2]),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: color1.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassWideCard({
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: [Colors.white.withOpacity(0.05), Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.6),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade700, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallGlassCard({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8)],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: bgBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: NetworkImage('https://f.top4top.io/p_3678r1i9x1.jpg'),
                fit: BoxFit.cover,
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [primaryMain, neonPurple]),
                    ),
                    child: const CircleAvatar(
                      radius: 38,
                      backgroundImage: NetworkImage('https://i.top4top.io/p_368142lj91.jpg'),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Olaa, $username",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 8)],
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                // CHANGE: Updated Logic for Sender Manage
                _buildDrawerItem(Icons.send_rounded, "Sender Manage", primaryAccent, () {
                  Navigator.pop(context);
                  if (role == 'owner') {
                    _showSenderTypeSelection();
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => BugSenderPage(sessionKey: sessionKey, username: username, role: role)));
                  }
                }),
                _buildDrawerItem(FontAwesomeIcons.whatsapp, "WhatsApp Tools", const Color(0xFF25D366), () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage(username: username, password: password, listBug: listBug, role: role, expiredDate: expiredDate, sessionKey: sessionKey)));
                }),
                _buildDrawerItem(Icons.verified_user, "NIK Checker", Colors.orange, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => NikCheckerPage()));
                }),
                _buildDrawerItem(Icons.vpn_key_rounded, "Change Password", Colors.pinkAccent, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordPage(username: username, sessionKey: sessionKey)));
                }),
                
                Divider(color: Colors.white.withOpacity(0.1), height: 30),
                
                _buildDrawerItem(Icons.storefront_rounded, "Seller Page", primaryMain, () {
                  Navigator.pop(context);
                  if (role == "reseller" || role == "owner") _onDrawerItemSelected(5);
                }),
                if (role == "owner")
                  _buildDrawerItem(Icons.admin_panel_settings_rounded, "Admin Panel", Colors.redAccent, () {
                    Navigator.pop(context);
                    _onDrawerItemSelected(6);
                  }),
                
                Divider(color: Colors.white.withOpacity(0.1), height: 30),
                
                _buildDrawerItem(Icons.logout_rounded, "Logout", Colors.grey, () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  void _showAccountMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: cardBlack,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text("Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textWhite)),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.lock_reset, color: primaryMain),
              title: Text("Change Password", style: TextStyle(color: textWhite)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordPage(username: username, sessionKey: sessionKey)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text("Logout", style: TextStyle(color: textWhite)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      extendBody: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: bgBlack.withOpacity(0.5)),
          ),
        ),
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryMain.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.code, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.white, Colors.cyanAccent],
              ).createShader(bounds),
              child: const Text("Demonix Reaper", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryAccent.withOpacity(0.5), width: 2),
              boxShadow: [BoxShadow(color: primaryAccent.withOpacity(0.2), blurRadius: 10)],
            ),
            child: InkWell(
              onTap: _showAccountMenu,
              borderRadius: BorderRadius.circular(50),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.transparent,
                backgroundImage: NetworkImage('https://h.top4top.io/p_3646nom7r1.jpg'),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: FadeTransition(opacity: _animation, child: _selectedPage),
      
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color: cardBlack.withOpacity(0.9), 
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: primaryAccent,
              unselectedItemColor: Colors.grey.shade600,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedTabIndex,
              onTap: _onTabTapped,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded),
                  activeIcon: Icon(Icons.dashboard_customize_rounded),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.construction_rounded),
                  label: "Tools",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.auto_stories_rounded),
                  label: "Komik",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.psychology_rounded),
                  label: "AI Chat",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    channel.sink.close(status.goingAway);
    _controller.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}

class _ParticlePainter extends CustomPainter {
  final Color color;
  final Random _random = Random();

  _ParticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (int i = 0; i < 20; i++) {
      double x = _random.nextDouble() * size.width;
      double y = _random.nextDouble() * size.height;
      double r = _random.nextDouble() * 3;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NewsMedia extends StatefulWidget {
  final String url;
  const NewsMedia({super.key, required this.url});

  @override
  State<NewsMedia> createState() => _NewsMediaState();
}

class _NewsMediaState extends State<NewsMedia> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (_isVideo(widget.url)) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          if (mounted) setState(() {});
          _controller?.setLooping(true);
          _controller?.setVolume(0.0);
          _controller?.play();
        });
    }
  }

  bool _isVideo(String url) {
    return url.endsWith(".mp4") ||
        url.endsWith(".webm") ||
        url.endsWith(".mov") ||
        url.endsWith(".mkv");
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo(widget.url)) {
      if (_controller != null && _controller!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        );
      } else {
        return const Center(
            child: CircularProgressIndicator(color: Colors.purpleAccent));
      }
    } else {
      return Image.network(
        widget.url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade900,
          child: const Icon(Icons.error, color: Colors.purpleAccent),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.purpleAccent,
            ),
          );
        },
      );
    }
  }
}