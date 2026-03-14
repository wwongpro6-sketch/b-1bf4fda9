import 'dart:convert';
import 'dart:ui'; // Diperlukan untuk ImageFilter
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BugSenderPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;

  const BugSenderPage({
    super.key,
    required this.sessionKey,
    required this.username,
    required this.role,
  });

  @override
  State<BugSenderPage> createState() => _BugSenderPageState();
}

class _BugSenderPageState extends State<BugSenderPage> with TickerProviderStateMixin {
  List<dynamic> senderList = [];
  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;
  
  // Animation Controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;

  // --- PALET WARNA CYBER-HOLO 2026 ---
  final Color bgDark = const Color(0xFF020205); // Absolute Black
  final Color bgDeep = const Color(0xFF0B0F19); // Deep Space Blue
  final Color accentCyan = const Color(0xFF00F0FF); // Cyber Cyan
  final Color accentPink = const Color(0xFFFF0055); // Neon Pink
  final Color accentPurple = const Color(0xFFBC13FE); // Electric Purple
  final Color glassWhite = const Color(0xFFFFFFFF).withOpacity(0.05);
  final Color glassBorder = const Color(0xFFFFFFFF).withOpacity(0.1);
  final Color successGreen = const Color(0xFF00FF9D); // Matrix Green
  final Color dangerRed = const Color(0xFFFF2A2A); // Alert Red

  @override
  void initState() {
    super.initState();
    // Animasi Fade In List
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController, 
      curve: Curves.fastOutSlowIn
    );

    // Animasi Pulse untuk tombol utama
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animationController.forward();
    _fetchSenders();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // --- LOGIC FETCH DATA ---
  Future<void> _fetchSenders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse("http://159.195.64.135:4000/mySender?key=${widget.sessionKey}"),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["valid"] == true) {
          setState(() {
            senderList = data["connections"] ?? [];
          });
        } else {
          setState(() {
            errorMessage = data["message"] ?? "Failed to fetch senders";
          });
        }
      } else {
        setState(() {
          errorMessage = "Server error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Connection failed: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  Future<void> _refreshSenders() async {
    setState(() => isRefreshing = true);
    await _fetchSenders();
  }

  // --- DIALOG ADD SENDER ---
  void _showAddSenderDialog() {
    final phoneController = TextEditingController();
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Efek Glow di belakang dialog
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accentPurple.withOpacity(0.3), Colors.transparent],
                  radius: 0.7,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: bgDeep.withOpacity(0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: accentCyan.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(color: accentCyan.withOpacity(0.1), blurRadius: 30, spreadRadius: 1),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.add_link_rounded, color: accentCyan, size: 28),
                          const SizedBox(width: 12),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [accentCyan, accentPurple],
                            ).createShader(bounds),
                            child: const Text(
                              "NEW CONNECTION",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Orbitron',
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildCyberTextField(
                        controller: phoneController,
                        label: "PHONE NUMBER",
                        icon: Icons.phone_iphone_rounded,
                        hint: "628xxxxx",
                        inputType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildCyberTextField(
                        controller: nameController,
                        label: "DEVICE NAME (OPTIONAL)",
                        icon: Icons.label_outline_rounded,
                        hint: "My Bot V1",
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("CANCEL", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                          ),
                          const SizedBox(width: 12),
                          _buildCyberButton(
                            text: "CONNECT",
                            color: accentCyan,
                            onPressed: () async {
                              final number = phoneController.text.trim();
                              final name = nameController.text.trim();
                              if (number.isEmpty) {
                                _showSnackBar("Please enter phone number", isError: true);
                                return;
                              }
                              Navigator.pop(context);
                              await _addSender(number, name);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER UNTUK TEXTFIELD KEREN ---
  Widget _buildCyberTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType inputType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: accentCyan.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: glassBorder),
          ),
          child: TextField(
            controller: controller,
            keyboardType: inputType,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
              prefixIcon: Icon(icon, color: accentPurple.withOpacity(0.7)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  // --- LOGIC ADD SENDER ---
  Future<void> _addSender(String number, String name) async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("http://159.195.64.135:4000/getPairing?key=${widget.sessionKey}&number=$number"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["valid"] == true) {
          _showPairingCodeDialog(number, data['pairingCode'], name);
          _showSnackBar("Pairing code generated!", isError: false);
        } else {
          _showSnackBar(data['message'] ?? "Failed to generate pairing code", isError: true);
        }
      } else {
        _showSnackBar("Server error: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      _showSnackBar("Connection failed: $e", isError: true);
    } finally {
      setState(() => isLoading = false);
      _fetchSenders();
    }
  }

  // --- DIALOG PAIRING CODE KEREN ---
  void _showPairingCodeDialog(String number, String code, String name) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgDark.withOpacity(0.95),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: successGreen.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(color: successGreen.withOpacity(0.15), blurRadius: 40),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.qr_code_scanner, color: successGreen, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                "LINK DEVICE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter this code on WhatsApp Linked Devices",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: successGreen.withOpacity(0.5)),
                ),
                child: Center(
                  child: SelectableText(
                    code,
                    style: TextStyle(
                      color: successGreen,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      fontFamily: 'Courier',
                      shadows: [
                        Shadow(color: successGreen.withOpacity(0.8), blurRadius: 10),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CLOSE"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: successGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _fetchSenders();
                      },
                      child: const Text("DONE", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- LOGIC DELETE ---
  Future<void> _deleteSender(String senderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgDark.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: dangerRed.withOpacity(0.5)),
            boxShadow: [BoxShadow(color: dangerRed.withOpacity(0.1), blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, color: dangerRed, size: 50),
              const SizedBox(height: 16),
              const Text("DISCONNECT?", style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text("This action will remove the bot session permanently.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.6))),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("CANCEL", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: dangerRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("DELETE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      setState(() => isLoading = true);
      try {
        final response = await http.delete(
          Uri.parse("http://159.195.64.135:4000/deleteSender?key=${widget.sessionKey}&id=$senderId"),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data["valid"] == true) {
            _showSnackBar("Session terminated.", isError: false);
            _fetchSenders();
          } else {
            _showSnackBar(data["message"] ?? "Delete failed", isError: true);
          }
        } else {
          _showSnackBar("Server error: ${response.statusCode}", isError: true);
        }
      } catch (e) {
        _showSnackBar("Connection failed: $e", isError: true);
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? dangerRed : successGreen.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  // --- WIDGET TOMBOL KEREN ---
  Widget _buildCyberButton({required String text, required Color color, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 15, spreadRadius: -5),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      ),
    );
  }

  // --- CARD ITEM ---
  Widget _buildSenderCard(Map<String, dynamic> sender, int index) {
    final name = sender['sessionName'] ?? 'Unknown Device';
    final number = sender['phone'] ?? 'No Number';
    final status = sender['connected'] ?? false;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: glassWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: glassBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                splashColor: accentPurple.withOpacity(0.1),
                onTap: () {}, // Bisa ditambah detail view
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Status Indicator with Pulse
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (status)
                            ScaleTransition(
                              scale: Tween(begin: 1.0, end: 1.5).animate(_pulseController),
                              child: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: successGreen.withOpacity(0.2)),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: status ? [successGreen, const Color(0xFF004d40)] : [dangerRed, const Color(0xFF4d0000)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: status ? successGreen.withOpacity(0.5) : dangerRed.withOpacity(0.5),
                                  blurRadius: 10,
                                )
                              ],
                            ),
                            child: Icon(
                              status ? Icons.wifi : Icons.wifi_off,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Info Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              number,
                              style: TextStyle(
                                color: accentCyan.withOpacity(0.8),
                                fontFamily: 'Courier',
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Delete Action
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: dangerRed.withOpacity(0.7)),
                        onPressed: () => _deleteSender(sender['id']),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- MAIN BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      extendBodyBehindAppBar: true,
      
      // AppBar Transparan
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.white, accentCyan],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: const Text(
            "DEVICE MANAGER",
            style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sync, color: accentCyan),
            onPressed: isLoading ? null : _refreshSenders,
          ),
        ],
      ),

      // Body dengan Background Cyber
      body: Stack(
        children: [
          // Background Gradient Orbs (FIXED: Menggunakan ImageFiltered)
          Positioned(
            top: -100,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  color: accentPurple.withOpacity(0.15),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  color: accentCyan.withOpacity(0.1),
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Header Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: glassWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: glassBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_moon, color: accentPurple, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "SESSION SECURE • ${widget.username.toUpperCase()}",
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // List View
                  Expanded(
                    child: isLoading && senderList.isEmpty
                        ? Center(child: CircularProgressIndicator(color: accentCyan))
                        : errorMessage != null && senderList.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.wifi_tethering_error_rounded, size: 60, color: dangerRed.withOpacity(0.5)),
                                    const SizedBox(height: 16),
                                    Text(errorMessage!, style: TextStyle(color: Colors.white.withOpacity(0.5))),
                                    TextButton(
                                      onPressed: _fetchSenders,
                                      child: Text("RETRY CONNECTION", style: TextStyle(color: accentCyan)),
                                    )
                                  ],
                                ),
                              )
                            : senderList.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.devices_other, size: 80, color: Colors.white.withOpacity(0.1)),
                                        const SizedBox(height: 20),
                                        Text("NO ACTIVE DEVICES", style: TextStyle(color: Colors.white.withOpacity(0.3), fontFamily: 'Orbitron', fontSize: 18)),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    color: accentCyan,
                                    backgroundColor: bgDeep,
                                    onRefresh: _refreshSenders,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.only(bottom: 100),
                                      itemCount: senderList.length,
                                      itemBuilder: (context, index) => _buildSenderCard(senderList[index], index),
                                    ),
                                  ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Floating Action Button Futuristik
      floatingActionButton: ScaleTransition(
        scale: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: accentPink.withOpacity(0.4), blurRadius: 20, spreadRadius: -2),
            ],
            gradient: LinearGradient(
              colors: [accentPink, accentPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: FloatingActionButton(
            backgroundColor: Colors.transparent,
            elevation: 0,
            onPressed: _showAddSenderDialog,
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}