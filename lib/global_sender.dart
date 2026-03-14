import 'dart:convert';
import 'dart:ui'; // Diperlukan untuk ImageFilter
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GlobalSenderPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;

  const GlobalSenderPage({
    super.key,
    required this.sessionKey,
    required this.username,
    required this.role,
  });

  @override
  State<GlobalSenderPage> createState() => _GlobalSenderPageState();
}

class _GlobalSenderPageState extends State<GlobalSenderPage> with TickerProviderStateMixin {
  // --- KONFIGURASI SERVER ---
  // Ganti URL ini jika port/domain berubah
  final String baseUrl = "http://159.195.64.135:4000"; 

  List<dynamic> senderList = [];
  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;
  
  // Animation Controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;

  // --- PALET WARNA CYBER-HOLO (GOLD/ORANGE VERSION FOR GLOBAL) ---
  final Color bgDark = const Color(0xFF020205); 
  final Color bgDeep = const Color(0xFF0B0F19); 
  final Color accentGold = const Color(0xFFFFD700); // Gold untuk Global
  final Color accentOrange = const Color(0xFFFF8C00); // Dark Orange
  final Color accentCyan = const Color(0xFF00F0FF); 
  final Color glassWhite = const Color(0xFFFFFFFF).withOpacity(0.05);
  final Color glassBorder = const Color(0xFFFFFFFF).withOpacity(0.1);
  final Color successGreen = const Color(0xFF00FF9D); 
  final Color dangerRed = const Color(0xFFFF2A2A); 

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController, 
      curve: Curves.fastOutSlowIn
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animationController.forward();
    _fetchGlobalSenders();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // --- API: LIST GLOBAL SENDERS ---
  Future<void> _fetchGlobalSenders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Mengambil List Global Sender
      final response = await http.get(
        Uri.parse("$baseUrl/api/admin/listGlobalSenders?key=${widget.sessionKey}"),
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
            errorMessage = data["message"] ?? "Access Denied";
          });
        }
      } else {
        setState(() => errorMessage = "Server error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => errorMessage = "Connection failed: $e");
    } finally {
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  Future<void> _refreshSenders() async {
    setState(() => isRefreshing = true);
    await _fetchGlobalSenders();
  }

  // --- API: ADD GLOBAL SENDER ---
  Future<void> _addGlobalSender(String number, String name) async {
    setState(() => isLoading = true);
    try {
      // FIX: Menggunakan /getPairing dengan type=global agar mendapat Kode Pairing
      final response = await http.get(
        Uri.parse("$baseUrl/getPairing?key=${widget.sessionKey}&number=$number&type=global"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["valid"] == true) {
          // Menampilkan dialog jika pairingCode tersedia
          if (data['pairingCode'] != null) {
             _showPairingCodeDialog(number, data['pairingCode'].toString());
             _showSnackBar("Global Pairing Initiated!", isError: false);
          } else {
             _showSnackBar("Session Created. Check Console.", isError: false);
          }
        } else {
          _showSnackBar(data['message'] ?? "Failed to add global sender", isError: true);
        }
      } else {
        _showSnackBar("Server error: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      _showSnackBar("Connection failed: $e", isError: true);
    } finally {
      setState(() => isLoading = false);
      _fetchGlobalSenders(); // Refresh list setelah add
    }
  }

  // --- API: DELETE GLOBAL SENDER ---
  Future<void> _deleteGlobalSender(String id) async {
    final confirmed = await _showConfirmDialog();
    if (!confirmed) return;

    setState(() => isLoading = true);
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/api/admin/deleteGlobalSender?key=${widget.sessionKey}&id=$id"),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["valid"] == true) {
          _showSnackBar("Global Node Terminated.", isError: false);
          _fetchGlobalSenders();
        } else {
          _showSnackBar(data["message"] ?? "Delete failed", isError: true);
        }
      } else {
        _showSnackBar("Server error: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  // --- UI COMPONENTS ---

  void _showAddSenderDialog() {
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accentGold.withOpacity(0.3), Colors.transparent],
                  radius: 0.7,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: bgDeep.withOpacity(0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: accentGold.withOpacity(0.3), width: 1),
                boxShadow: [BoxShadow(color: accentGold.withOpacity(0.1), blurRadius: 30)],
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
                          Icon(Icons.public, color: accentGold, size: 28),
                          const SizedBox(width: 12),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(colors: [accentGold, accentOrange]).createShader(bounds),
                            child: const Text("NEW GLOBAL NODE", style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
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
                            text: "INITIALIZE",
                            color: accentGold,
                            onPressed: () {
                              if (phoneController.text.isNotEmpty) {
                                Navigator.pop(context);
                                _addGlobalSender(phoneController.text.trim(), "Global");
                              }
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

  void _showPairingCodeDialog(String number, String code) {
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
            border: Border.all(color: accentGold.withOpacity(0.5), width: 1),
            boxShadow: [BoxShadow(color: accentGold.withOpacity(0.15), blurRadius: 40)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_2, color: accentGold, size: 50),
              const SizedBox(height: 20),
              const Text("GLOBAL PAIRING", style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Enter this code on WhatsApp > Linked Devices", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentGold.withOpacity(0.5)),
                ),
                child: Center(
                  child: SelectableText(
                    code,
                    style: TextStyle(color: accentGold, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 6, fontFamily: 'Courier'),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: accentGold, foregroundColor: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                  _fetchGlobalSenders();
                },
                child: const Text("DONE", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgDark.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: dangerRed.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber, color: dangerRed, size: 40),
              const SizedBox(height: 16),
              const Text("TERMINATE NODE?", style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Orbitron')),
              const SizedBox(height: 12),
              Text("This will disconnect the global session.", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL", style: TextStyle(color: Colors.white)))),
                  Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: dangerRed), onPressed: () => Navigator.pop(context, true), child: const Text("DELETE"))),
                ],
              )
            ],
          ),
        ),
      ),
    ) ?? false;
  }

  // --- HELPERS ---
  Widget _buildCyberTextField({required TextEditingController controller, required String label, required IconData icon, required String hint, TextInputType inputType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: accentGold.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(16), border: Border.all(color: glassBorder)),
          child: TextField(
            controller: controller,
            keyboardType: inputType,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)), prefixIcon: Icon(icon, color: accentOrange.withOpacity(0.7)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildCyberButton({required String text, required Color color, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 15, spreadRadius: -5)]),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: isError ? dangerRed : successGreen.withOpacity(0.9), behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(20)));
  }

  // --- MAIN BUILD ---
  @override
  Widget build(BuildContext context) {
    // PROTEKSI: Hanya Owner/VIP
    if (!["owner"].contains(widget.role.toLowerCase())) {
      return Scaffold(
        backgroundColor: bgDark,
        body: Center(child: Text("ACCESS DENIED\nRESTRICTED AREA", textAlign: TextAlign.center, style: TextStyle(color: dangerRed, fontFamily: 'Orbitron', fontSize: 24, fontWeight: FontWeight.bold))),
      );
    }

    return Scaffold(
      backgroundColor: bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white)),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(colors: [Colors.white, accentGold]).createShader(bounds),
          child: const Text("GLOBAL NODES", style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.bold, letterSpacing: 2)),
        ),
        actions: [IconButton(icon: Icon(Icons.sync, color: accentGold), onPressed: isLoading ? null : _refreshSenders)],
      ),
      body: Stack(
        children: [
          // Background Cyber
          Positioned(top: -100, right: -100, child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: accentOrange.withOpacity(0.15))))),
          Positioned(bottom: -50, left: -50, child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: accentGold.withOpacity(0.1))))),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: glassWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: glassBorder)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.public_off_outlined, color: accentGold, size: 16),
                        const SizedBox(width: 8),
                        Text("SYSTEM LEVEL ACCESS • OWNER ONLY", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // List
                  Expanded(
                    child: isLoading && senderList.isEmpty
                        ? Center(child: CircularProgressIndicator(color: accentGold))
                        : senderList.isEmpty
                            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.dns_outlined, size: 80, color: Colors.white.withOpacity(0.1)), const SizedBox(height: 20), Text("NO GLOBAL NODES ACTIVE", style: TextStyle(color: Colors.white.withOpacity(0.3), fontFamily: 'Orbitron', fontSize: 16))]))
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 100),
                                itemCount: senderList.length,
                                itemBuilder: (context, index) {
                                  final item = senderList[index];
                                  final isConnected = item['connected'] ?? false;
                                  return FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(color: glassWhite, borderRadius: BorderRadius.circular(24), border: Border.all(color: glassBorder), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(16),
                                        leading: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            if (isConnected) ScaleTransition(scale: Tween(begin: 1.0, end: 1.5).animate(_pulseController), child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: successGreen.withOpacity(0.2)))),
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: isConnected ? [successGreen, const Color(0xFF004d40)] : [dangerRed, const Color(0xFF4d0000)]), boxShadow: [BoxShadow(color: isConnected ? successGreen.withOpacity(0.5) : dangerRed.withOpacity(0.5), blurRadius: 10)]),
                                              child: Icon(isConnected ? Icons.language : Icons.public_off, color: Colors.white, size: 20),
                                            ),
                                          ],
                                        ),
                                        title: Text("GLOBAL NODE ${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', fontSize: 14)),
                                        subtitle: Text(item['phone'].toString(), style: TextStyle(color: accentGold.withOpacity(0.8), fontFamily: 'Courier')),
                                        trailing: IconButton(icon: Icon(Icons.remove_circle_outline, color: dangerRed), onPressed: () => _deleteGlobalSender(item['id'])),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: accentGold.withOpacity(0.4), blurRadius: 20)], gradient: LinearGradient(colors: [accentGold, accentOrange])),
          child: FloatingActionButton(backgroundColor: Colors.transparent, elevation: 0, onPressed: _showAddSenderDialog, child: const Icon(Icons.add_link, color: Colors.black, size: 30)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}