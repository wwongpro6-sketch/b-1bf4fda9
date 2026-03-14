import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart'; // Wajib install qr_flutter

class BuyAccountPage extends StatefulWidget {
  const BuyAccountPage({super.key});

  @override
  State<BuyAccountPage> createState() => _BuyAccountPageState();
}

class _BuyAccountPageState extends State<BuyAccountPage> {
  // IP VPS Anda (Port 2467)
  final String baseUrl = "http://159.195.64.135:4000";

  final _userController = TextEditingController();
  final _passController = TextEditingController();
  
  // Pilihan Paket
  int _selectedDuration = 30; 
  String _selectedRole = "member";
  int _price = 10000;

  bool _isLoading = false;
  
  // Variabel Baru untuk Logika QR & Polling
  String? qrData;      // Menyimpan data string QRIS dari server
  Timer? _timer;       // Timer untuk cek status otomatis
  String? _orderId;    // ID Transaksi saat ini

  // Colors (Neon Theme)
  final Color primaryPurple = const Color(0xFFD500F9);
  final Color primaryPink = const Color(0xFFFF4081);
  final Color bgBlack = const Color(0xFF050505);

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _timer?.cancel(); // Matikan timer saat keluar halaman
    super.dispose();
  }

  void _updatePrice(int days) {
    setState(() {
      _selectedDuration = days;
      _price = (days == 30) ? 10000 : 20000;
    });
  }

  // Fungsi Baru: Generate QR Code tanpa membuka Browser
  Future<void> _processPayment() async {
    final username = _userController.text.trim();
    final password = _passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Username dan Password tidak boleh kosong!"), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Request ke Server Node.js untuk dapatkan teks QRIS
      final response = await http.post(
        Uri.parse("$baseUrl/create-payment-auto"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "newUser": username,
          "pass": password,
          "duration": _selectedDuration.toString(),
          "role": _selectedRole,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        setState(() {
          qrData = data['qrData']; // Simpan teks QRIS
          _orderId = data['orderId'];
        });

        // Mulai cek status pembayaran otomatis
        _startPolling(data['orderId'], data['amount']);
        
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: ${data['message']}"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Fungsi Baru: Cek status setiap 5 detik (Polling)
  void _startPolling(String orderId, int amount) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final res = await http.get(Uri.parse("$baseUrl/cek-status?orderId=$orderId&amount=$amount"));
        final status = jsonDecode(res.body);

        if (status['paid'] == true) {
          timer.cancel(); // Stop checking
          _showSuccessDialog(); // Tampilkan popup sukses
        }
      } catch (_) {}
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: primaryPurple)
        ),
        title: const Text("PAYMENT SUCCESS", style: TextStyle(color: Colors.greenAccent)),
        content: const Text("Pembayaran diterima! Akun Anda telah aktif otomatis.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup Dialog
              Navigator.pop(context); // Kembali ke Landing Page / Login
            },
            child: const Text("LOGIN SEKARANG", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      resizeToAvoidBottomInset: true, 
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F0518), Colors.black],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Tombol Back & Judul
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                            ),
                            Text(
                              "BUY PREMIUM",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                                shadows: [Shadow(color: primaryPurple, blurRadius: 15)],
                              ),
                            ),
                            const SizedBox(width: 20), // Spacer agar judul di tengah
                          ],
                        ),
                        const SizedBox(height: 30),

                        // --- LOGIKA TAMPILAN: FORM vs QR CODE ---
                        if (qrData != null) 
                          _buildQRView() // Tampilkan QR jika data sudah ada
                        else 
                          _buildFormView(), // Tampilkan Form jika belum request

                      ],
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

  // --- WIDGET 1: TAMPILAN FORMULIR ---
  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("SET USERNAME"),
        _buildGlassInput(_userController, "New Username", Icons.person),
        const SizedBox(height: 15),
        _buildLabel("SET PASSWORD"),
        _buildGlassInput(_passController, "New Password", Icons.lock),

        const SizedBox(height: 25),
        _buildLabel("CHOOSE PLAN"),
        
        Row(
          children: [
            Expanded(child: _buildPlanCard("1 MONTH", "IDR 15.000", 30)),
            const SizedBox(width: 15),
            Expanded(child: _buildPlanCard("PERMANENT", "IDR 25.000", 9999)),
          ],
        ),

        const SizedBox(height: 30),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: primaryPink.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TOTAL:", style: TextStyle(color: Colors.white70)),
              Text(
                "Rp ${_price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}",
                style: TextStyle(color: primaryPink, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _processPayment, // Panggil _processPayment yang baru
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryPurple, primaryPink]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: primaryPurple.withOpacity(0.4), blurRadius: 15)],
              ),
              child: Container(
                alignment: Alignment.center,
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("GET QR CODE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGET 2: TAMPILAN QR CODE (SETELAH KLIK BAYAR) ---
  Widget _buildQRView() {
    return Column(
      children: [
        const Icon(Icons.qr_code_scanner, color: Colors.white, size: 50),
        const SizedBox(height: 10),
        const Text(
          "SCAN TO PAY",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        const SizedBox(height: 5),
        const Text(
          "Sistem otomatis mengecek pembayaran...",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 20),

        // Kotak Putih untuk QR Code agar kontras
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: QrImageView(
            data: qrData!,
            version: QrVersions.auto,
            size: 220.0,
          ),
        ),

        const SizedBox(height: 30),
        
        // Indikator Loading
        const CircularProgressIndicator(),
        const SizedBox(height: 10),
        Text("Menunggu Pembayaran...", style: TextStyle(color: primaryPink)),

        const SizedBox(height: 20),
        
        // Tombol Cancel
        TextButton(
          onPressed: () {
            setState(() {
              qrData = null; // Reset tampilan ke Form
              _timer?.cancel();
            });
          },
          child: const Text("BATALKAN / KEMBALI", style: TextStyle(color: Colors.white54)),
        )
      ],
    );
  }

  // --- WIDGET HELPER LAINNYA ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 5),
      child: Text(text, style: TextStyle(color: primaryPurple, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildGlassInput(TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildPlanCard(String title, String price, int days) {
    bool isSelected = _selectedDuration == days;
    return GestureDetector(
      onTap: () => _updatePrice(days),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? primaryPurple.withOpacity(0.2) : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? primaryPurple : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 5),
            Text(price, style: TextStyle(color: isSelected ? primaryPink : Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}