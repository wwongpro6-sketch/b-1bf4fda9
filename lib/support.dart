import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui'; // Diperlukan untuk ImageFilter

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  // --- COLOR PALETTE (Sesuai Tema Dashboard) ---
  final Color bgBlack = const Color(0xFF080C15);
  final Color cardBlack = const Color(0xFF161F30);
  final Color neonBlue = const Color(0xFF536DFE); // Primary
  final Color neonCyan = const Color(0xFF40C4FF); // Accent

  // --- 1. DATA MEMBER (Updated: 20 Members) ---
  final List<Map<String, String>> members = [
    // Original 4
    {
      "name": "tzy",
      "role": "Developer",
      "image": "https://a.top4top.io/p_36798lzjs1.jpg", 
      "link": "https://t.me/PdlPdf", 
    },
    {
      "name": "hafzz", 
      "role": "Friends",
      "image": "https://b.top4top.io/p_3683j07891.jpg",
      "link": "https://t.me/hafz_reals", 
    },
    {
      "name": "zydxy",
      "role": "Friends",
      "image": "https://f.top4top.io/p_36792v63g1.jpg",
      "link": "https://t.me/ZidxyzzEllThomas", 
    },
    // Added 16 New Members
    {
      "name": "Otax",
      "role": "Friends",
      "image": "https://l.top4top.io/p_3683umn9w1.jpg",
      "link": "https://t.me/Otapengenkawin", 
    },
    {
      "name": "sanzz",
      "role": "Friends",
      "image": "https://i.top4top.io/p_3683gzcs71.jpg",
      "link": "https://t.me/SanzzzOfficial", 
    },
    {
      "name": "sadzx",
      "role": "Friends",
      "image": "https://i.top4top.io/p_36832bfoj1.jpg",
      "link": "https://t.me/Sadzxajh", 
    },
  ];

  // --- 2. FUNCTION LAUNCH TELEGRAM ---
  Future<void> _launchTelegram(String urlString) async {
    final Uri url = Uri.parse(urlString); 
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Support Center", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // --- BACKGROUND GLOW EFFECT (FIXED) ---
          Positioned(
            top: -100,
            left: -100,
            child: ImageFiltered( // Menggunakan ImageFiltered untuk efek blur
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: neonBlue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          
          // --- MAIN CONTENT ---
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // HEADER TEXT
                  Text(
                    "Credits & Thanks To",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontFamily: 'Courier',
                      shadows: [
                        Shadow(color: neonBlue, blurRadius: 15),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Meet the brilliant minds behind this project",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // GRID CARDS
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, 
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.75, 
                    ),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return _buildMemberCard(
                        name: member['name']!,
                        role: member['role']!,
                        telegramUrl: member['link']!, 
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                  
                  // FOOTER
                  Text(
                    "© 2024 Narukami Project",
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
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

  // --- WIDGET CARD ---
  Widget _buildMemberCard({
    required String name, 
    required String role, 
    required String telegramUrl
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBlack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: neonBlue.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar Circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: neonCyan, 
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: neonCyan.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ],
            ),
            child: const Center(
              child: Icon(Icons.person, color: Colors.transparent, size: 40), 
            ),
          ),
          
          const SizedBox(height: 15),

          // Name
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
            ),
          ),

          const SizedBox(height: 5),

          // Role
          Text(
            role.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: neonBlue,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),

          const SizedBox(height: 15),

          // Contact Button
          GestureDetector(
            onTap: () => _launchTelegram(telegramUrl),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(FontAwesomeIcons.telegram, color: Color(0xFF29B6F6), size: 14),
                  const SizedBox(width: 8),
                  Text(
                    "Contact",
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}