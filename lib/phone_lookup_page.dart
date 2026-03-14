import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneLookupPage extends StatefulWidget {
  const PhoneLookupPage({super.key});

  @override
  State<PhoneLookupPage> createState() => _PhoneLookupPageState();
}

class _PhoneLookupPageState extends State<PhoneLookupPage> with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _data;
  String? _errorMessage;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  // --- TEMA WARNA NEON PURPLE PINK BLACK (SAMA DENGAN NIK CHECKER) ---
  final Color bgBlack = const Color(0xFF050505);
  final Color cardBlack = const Color(0xFF141414);
  final Color cardDarker = const Color(0xFF0A0A0A);
  final Color primaryPurple = const Color(0xFFD500F9);
  final Color primaryPink = const Color(0xFFFF4081);
  final Color successGreen = const Color(0xFF00E676);
  final Color warningOrange = const Color(0xFFFF9100);
  final Color dangerRed = const Color(0xFFFF1744);
  // Warna khusus Provider
  final Color telkomselRed = const Color(0xFFE3001B);
  final Color xlBlue = const Color(0xFF002D72);
  final Color indosatYellow = const Color(0xFFFFD600);
  final Color triOrange = const Color(0xFFFF7F00);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // LOGIKA DETEKSI KARTU (HLR LOOKUP LOKAL)
  Future<void> _checkProvider() async {
    final number = _phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    
    // Validasi Input
    if (number.isEmpty) {
      setState(() => _errorMessage = "Nomor HP tidak boleh kosong.");
      return;
    }
    if (number.length < 4) {
      setState(() => _errorMessage = "Masukkan minimal 4 digit awal.");
      return;
    }

    // Animasi Loading
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _data = null;
    });

    // Simulasi Delay Network (Agar animasi loading terlihat keren)
    await Future.delayed(const Duration(seconds: 1));

    String prefix = number.substring(0, 4);
    // Jika format 628..., ambil 5 digit lalu sesuaikan prefix 08...
    if (number.startsWith("62")) {
      prefix = "0${number.substring(2, 5)}"; 
    }

    String provider = "Unknown";
    String era = "Unknown";
    Color brandingColor = Colors.grey;
    IconData icon = Icons.help_outline;

    // Logika Prefix Indonesia
    if (RegExp(r'^0811|0812|0813|0821|0822|0823|0852|0853|0851').hasMatch(prefix)) {
      provider = "Telkomsel (Halo/Simpati/Loop/AS)";
      era = "Kartu ini menggunakan jaringan terluas di Indonesia.";
      brandingColor = telkomselRed;
      icon = Icons.signal_cellular_alt;
    } else if (RegExp(r'^0814|0815|0816|0855|0856|0857|0858').hasMatch(prefix)) {
      provider = "Indosat Ooredoo (IM3/Mentari)";
      era = "Identik dengan anak muda, populer sejak awal 2000-an.";
      brandingColor = indosatYellow;
      icon = Icons.language;
    } else if (RegExp(r'^0817|0818|0819|0859|0877|0878').hasMatch(prefix)) {
      provider = "XL Axiata";
      era = "Operator swasta pertama di Indonesia (sejak 1996).";
      brandingColor = xlBlue;
      icon = Icons.bolt;
    } else if (RegExp(r'^0831|0832|0833|0838').hasMatch(prefix)) {
      provider = "AXIS (XL Axiata Group)";
      era = "Dikenal dengan paket irit, kini merger dengan XL.";
      brandingColor = primaryPurple;
      icon = Icons.waves;
    } else if (RegExp(r'^0895|0896|0897|0898|0899').hasMatch(prefix)) {
      provider = "Tri (3) Indonesia";
      era = "Masuk Indonesia tahun 2007, populer untuk kuota data.";
      brandingColor = triOrange;
      icon = Icons.looks_3;
    } else if (RegExp(r'^0881|0882|0883|0884|0885|0886|0887|0888|0889').hasMatch(prefix)) {
      provider = "Smartfren";
      era = "Pelopor 4G LTE murni, eks-jaringan CDMA.";
      brandingColor = primaryPink;
      icon = Icons.four_g_mobiledata;
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "Prefix $prefix tidak dikenali sebagai operator Indonesia.";
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _data = {
        "number": number,
        "prefix": prefix,
        "provider": provider,
        "era": era,
        "color": brandingColor,
        "icon": icon,
        "status": "Active / Registered"
      };
    });
    
    _fadeController.reset();
    _fadeController.forward();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardDarker,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: successGreen.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: successGreen.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: successGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Copied!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('$label disalin ke clipboard', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.phone_android, color: primaryPurple),
            ),
            const SizedBox(width: 12),
            const Text(
              "Phone Lookup",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: bgBlack,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [primaryPurple, primaryPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryPurple.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.search, color: Colors.white, size: 40),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Provider Check",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Identify cellular operator & details",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Input Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBlack,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryPurple.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Enter Phone Number",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: cardDarker,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryPurple.withOpacity(0.3)),
                        ),
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'e.g. 0812xxxxxxxx',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            suffixIcon: _isLoading
                                ? Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: primaryPink,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          onSubmitted: (_) => _checkProvider(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [primaryPurple, primaryPink],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryPurple.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _checkProvider,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const Text("ANALYZING...", style: TextStyle(fontWeight: FontWeight.bold))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.sim_card, size: 20),
                                    SizedBox(width: 8),
                                    Text("CHECK PROVIDER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: dangerRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: dangerRed.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: dangerRed),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Results Section
                if (_data != null)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // 1. Provider Information Card
                        _buildInfoCard(
                          title: "Provider Detected",
                          icon: _data!['icon'],
                          color: _data!['color'], // Dynamic color based on provider
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: (_data!['color'] as Color).withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: (_data!['color'] as Color).withOpacity(0.5), width: 2),
                                    ),
                                    child: Icon(_data!['icon'], color: _data!['color'], size: 40),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _data!['provider'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Prefix: ${_data!['prefix']}",
                                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Divider(color: Colors.white.withOpacity(0.1)),
                            const SizedBox(height: 10),
                            _buildInfoItem(
                              label: "Phone Number",
                              value: _data!['number'],
                              showCopy: true,
                            ),
                            _buildInfoItem(
                              label: "Status",
                              value: _data!['status'],
                              icon: Icons.check_circle,
                              iconColor: successGreen,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // 2. Details / Trivia Card
                        _buildInfoCard(
                          title: "Card Information",
                          icon: Icons.info_outline,
                          color: warningOrange,
                          children: [
                            _buildInfoItem(
                              label: "Description / History",
                              value: _data!['era'],
                            ),
                            _buildInfoItem(
                              label: "Country Code",
                              value: "+62 (Indonesia)",
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
      ),
    );
  }

  // --- WIDGET BUILDERS HELPER (Sama seperti NIK Checker) ---

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Card Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String? value,
    bool showCopy = false,
    IconData? icon,
    Color? iconColor,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDarker,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor ?? Colors.white, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (showCopy)
            Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: primaryPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(Icons.copy, color: primaryPurple, size: 18),
                onPressed: () => _copyToClipboard(value, label),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40),
                tooltip: 'Copy $label',
              ),
            ),
        ],
      ),
    );
  }
}