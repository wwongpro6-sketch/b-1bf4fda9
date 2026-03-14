import 'dart:convert';
import 'dart:ui'; // Diperlukan untuk efek Glass/Blur
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'splash.dart';

const String baseUrl = "http://159.195.64.135:4000";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final userController = TextEditingController();
  final passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool _obscurePassword = true;
  String? androidId;

  late AnimationController _slideController;
  late AnimationController _rotateController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _rotateAnim;

  // Warna Tema Neon Purple Pink Black
  final Color primaryPurple = const Color(0xFFD500F9); // Ungu Neon
  final Color primaryPink = const Color(0xFFFF4081);   // Pink Neon
  final Color darkBlack = const Color(0xFF000000);     // Hitam Pekat

  @override
  void initState() {
    super.initState();
    _initAnim();
    initLogin();
  }

  void _initAnim() {
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    _rotateAnim = Tween<double>(begin: 0, end: 1).animate(_rotateController);
  }

  Future<void> initLogin() async {
    androidId = await getAndroidId();

    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey = prefs.getString("key");

    if (savedUser != null && savedPass != null && savedKey != null) {
      final uri = Uri.parse(
          "$baseUrl/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey");

      try {
        final res = await http.get(uri);
        final data = jsonDecode(res.body);

        if (data['valid'] == true) {
          _navigate(savedUser, savedPass, data);
        }
      } catch (_) {}
    }
  }

  void _navigate(String user, String pass, Map<String, dynamic> data) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SplashScreen(
          username: user,
          password: pass,
          role: data['role'],
          sessionKey: data['key'],
          expiredDate: data['expiredDate'],
          listBug: (data['listBug'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
          listDoos: (data['listDDoS'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
          news: (data['news'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        ),
      ),
    );
  }

  Future<String> getAndroidId() async {
    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;
    return android.id ?? "unknown_device";
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    final username = userController.text.trim();
    final password = passController.text.trim();

    setState(() => isLoading = true);

    try {
      final validate = await http.post(
        Uri.parse("$baseUrl/validate"),
        body: {
          "username": username,
          "password": password,
          "androidId": androidId ?? "unknown_device",
        },
      );

      final validData = jsonDecode(validate.body);

      if (validData['expired'] == true) {
        _showPopup(
          title: "⏳ Access Expired",
          message: "Your access has expired.\nPlease renew it.",
          color: Colors.amber,
          showContact: true,
        );
      } else if (validData['valid'] != true) {
        _showPopup(
          title: "❌ Login Failed",
          message: "Invalid username or password.",
          color: Colors.redAccent,
        );
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("username", username);
        prefs.setString("password", password);
        prefs.setString("key", validData['key']);
        _navigate(username, password, validData);
      }
    } catch (e) {
      _showPopup(
        title: "⚠️ Connection Error",
        message: "Failed to connect to the server.\nPlease check your connection.",
        color: Colors.grey,
      );
    }

    setState(() => isLoading = false);
  }

  void _showPopup({
    required String title,
    required String message,
    Color color = Colors.white,
    bool showContact = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: primaryPurple.withOpacity(0.3))),
          title: Text(
            title,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            if (showContact)
              TextButton(
                onPressed: () async {
                  await launchUrl(Uri.parse("https://t.me/mizukisnji"),
                      mode: LaunchMode.externalApplication);
                },
                child: Text(
                  "Contact Admin",
                  style: TextStyle(color: primaryPink),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("Close", style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _rotateController.dispose();
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dasar hitam pekat
      body: Stack(
        children: [
          // 1. Background Gradient (Black to Deep Purple hint)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F0518), // Deep Dark Purple/Black
                    Color(0xFF000000), // Pure Black
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // 2. Animated Background Elements (Purple & Pink Glow)
          Positioned(
            top: -100,
            left: -100,
            child: AnimatedBuilder(
              animation: _rotateAnim,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateAnim.value * 2 * 3.14159,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryPurple.withOpacity(0.2), // Ungu Glow
                          blurRadius: 60,
                          spreadRadius: 10,
                        )
                      ],
                      gradient: LinearGradient(
                        colors: [
                          primaryPurple.withOpacity(0.15),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: AnimatedBuilder(
              animation: _rotateAnim,
              builder: (context, child) {
                return Transform.rotate(
                  angle: -_rotateAnim.value * 2 * 3.14159,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryPink.withOpacity(0.1), // Pink Border
                        width: 1,
                      ),
                      boxShadow: [
                         BoxShadow(
                          color: primaryPink.withOpacity(0.1),
                          blurRadius: 40,
                          spreadRadius: 5,
                        )
                      ]
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Main Glass Card
          Center(
            child: SingleChildScrollView(
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Efek Blur Kaca
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05), // Transparansi kaca gelap
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1), // Border kaca tipis
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 0,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo Section with Purple/Pink Glow
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryPurple.withOpacity(0.3),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: primaryPink.withOpacity(0.2),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                                border: Border.all(color: Colors.white24, width: 2),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo.jpg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, _, __) => Container(color: Colors.grey[900]),
                                ),
                              ),
                            ),

                            const SizedBox(height: 25),

                            Text(
                              "Demonix Reaper",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: primaryPurple, // Judul Ungu Menyala
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: primaryPink.withOpacity(0.5),
                                    blurRadius: 15,
                                  )
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 5),
                            
                            Text(
                              "Authentication",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                                letterSpacing: 1,
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Form
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _buildGlassInput(
                                    userController,
                                    "Username",
                                    Icons.person_outline,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildGlassInput(
                                    passController,
                                    "Password",
                                    Icons.lock_outline,
                                    isPassword: true,
                                  ),
                                  const SizedBox(height: 40),
                                  _buildGlowingButton(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassInput(TextEditingController controller, String label, IconData icon,
      {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3), // Lebih gelap untuk input
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildGlowingButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            primaryPurple, // Ungu
            primaryPink,   // Pink
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 5),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                "LOGIN",
                style: TextStyle(
                  color: Colors.white, // Teks putih agar kontras dengan background ungu/pink
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }
}