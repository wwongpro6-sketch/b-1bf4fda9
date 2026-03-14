import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class TelegramReportPage extends StatefulWidget {
  const TelegramReportPage({super.key});

  @override
  State<TelegramReportPage> createState() => _TelegramReportPageState();
}

class _TelegramReportPageState extends State<TelegramReportPage> with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _targetController = TextEditingController();
  
  // State
  String? _selectedReason;
  double _reportCount = 10;
  bool _isProcessing = false;
  String _processStatus = "";
  
  // Animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Colors (Neon Theme)
  final Color bgBlack = const Color(0xFF050505);
  final Color cardBlack = const Color(0xFF141414);
  final Color neonPurple = const Color(0xFFD500F9);
  final Color neonPink = const Color(0xFFFF4081);
  final Color textWhite = Colors.white;
  final Color textGrey = Colors.white70;

  // Data Alasan Report
  final List<Map<String, dynamic>> _reasons = [
    {"label": "🚫 Scam", "value": "Scam"},
    {"label": "👤 Fake Account", "value": "Fake Account"},
    {"label": "🔞 Pornography", "value": "Pornography"},
    {"label": "💊 Drugs / Illegal", "value": "Illegal Goods"},
    {"label": "⚠️ Spam", "value": "Spam"},
    {"label": "🤬 Harassment", "value": "Harassment"},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _targetController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // --- LOGIC REPORT (SPAM LOOP) ---
  Future<void> _startReport() async {
    final target = _targetController.text.trim();
    
    // 1. Validasi Input
    if (target.isEmpty) {
      _showSnackBar("Target username/ID is required!", Colors.redAccent);
      return;
    }
    
    // Validasi Format (Regex: @username atau ID angka)
    final isUsername = RegExp(r'^@[a-zA-Z0-9_]{5,32}$').hasMatch(target);
    final isId = RegExp(r'^[0-9]{5,15}$').hasMatch(target);

    if (!isUsername && !isId) {
       _showSnackBar("Invalid format! Use @username or numeric ID.", Colors.redAccent);
       return;
    }

    if (_selectedReason == null) {
      _showSnackBar("Please select a report reason.", Colors.orangeAccent);
      return;
    }

    // 2. Mulai Proses
    setState(() {
      _isProcessing = true;
      _processStatus = "Initializing...";
    });

    // Simulasi inisialisasi
    await Future.delayed(const Duration(seconds: 1));
    
    // 3. Loop Spam Report
    int total = _reportCount.toInt();
    int batchSize = (total / 5).ceil(); // Bagi proses menjadi 5 batch visual

    for (int i = 1; i <= 5; i++) { 
      if (!mounted) return;
      
      // Update status visual
      setState(() {
        _processStatus = "Sending report batch $i/5 (${i * batchSize} sent)...";
      });
      
      // Simulasi delay pengiriman (Ganti ini dengan HTTP Call ke API jika sudah ada)
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // 4. Selesai
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _processStatus = "";
      });
      
      _showSuccessDialog(target, total);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: color.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog(String target, int total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: cardBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: neonPurple, width: 2)
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: neonPurple),
              const SizedBox(width: 10),
              const Text("Report Sent", style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogRow("Target", target),
              _buildDialogRow("Reason", _selectedReason!),
              _buildDialogRow("Total", "$total Reports"),
              _buildDialogRow("Status", "Success ✅"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _targetController.clear();
                setState(() {
                  _selectedReason = null;
                  _reportCount = 10;
                });
              },
              child: Text("Done", style: TextStyle(color: neonPink, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textGrey, fontSize: 14)),
          Text(value, style: TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  // --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        backgroundColor: bgBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "TELEGRAM REPORTER",
          style: TextStyle(
            color: textWhite,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 18,
            fontFamily: 'Orbitron',
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Gradient Mesh
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [neonPurple.withOpacity(0.2), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [neonPink.withOpacity(0.2), Colors.transparent],
                ),
              ),
            ),
          ),

          // Main Content
          FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Target Input
                  _buildSectionTitle("Target Info", Icons.person_search),
                  const SizedBox(height: 15),
                  _buildInputBox(),
                  
                  const SizedBox(height: 30),

                  // 2. Reason Selection
                  _buildSectionTitle("Report Reason", Icons.warning_amber_rounded),
                  const SizedBox(height: 15),
                  _buildReasonGrid(),

                  const SizedBox(height: 30),

                  // 3. Amount Slider
                  _buildSectionTitle("Report Quantity", Icons.speed),
                  const SizedBox(height: 10),
                  _buildSlider(),

                  const SizedBox(height: 40),

                  // 4. Send Button
                  _buildSendButton(),
                  
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      "Powered by Narukami Tools",
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Processing Overlay
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: neonPink, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: textWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron', 
          ),
        ),
      ],
    );
  }

  Widget _buildInputBox() {
    return Container(
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4)),
        ]
      ),
      child: TextField(
        controller: _targetController,
        style: TextStyle(color: textWhite),
        decoration: InputDecoration(
          hintText: "Enter @username or ID (e.g. 12345678)",
          hintStyle: const TextStyle(color: Colors.white30),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: Icon(Icons.telegram, color: neonPurple),
        ),
      ),
    );
  }

  Widget _buildReasonGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _reasons.map((reason) {
        final isSelected = _selectedReason == reason['value'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedReason = reason['value'];
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? neonPurple.withOpacity(0.2) : cardBlack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? neonPurple : Colors.white12,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              reason['label'],
              style: TextStyle(
                color: isSelected ? textWhite : textGrey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("10", style: TextStyle(color: textGrey, fontSize: 12)),
            Text(
              "${_reportCount.toInt()} Reports",
              style: TextStyle(color: neonPink, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text("1000", style: TextStyle(color: textGrey, fontSize: 12)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: neonPink,
            inactiveTrackColor: Colors.white12,
            thumbColor: textWhite,
            overlayColor: neonPink.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 4,
          ),
          child: Slider(
            value: _reportCount,
            min: 10,
            max: 1000,
            divisions: 99,
            onChanged: (value) {
              setState(() {
                _reportCount = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _startReport,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [neonPurple, neonPink],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: neonPurple.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: const Center(
          child: Text(
            "START REPORTING",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontFamily: 'Orbitron', 
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: bgBlack.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60, height: 60,
              child: CircularProgressIndicator(
                color: neonPurple,
                strokeWidth: 4,
                backgroundColor: Colors.white12,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "PROCESSING",
              style: TextStyle(
                color: textWhite,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 2,
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _processStatus,
              style: TextStyle(color: neonPink, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}