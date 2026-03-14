import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class PublicChatPage extends StatefulWidget {
  final String username;
  const PublicChatPage({super.key, required this.username});

  @override
  State<PublicChatPage> createState() => _PublicChatPageState();
}

class _PublicChatPageState extends State<PublicChatPage> {
  // --- KONFIGURASI URL SERVER ---
  // Pastikan ini sama dengan server index.js Anda
  final String baseUrl = "http://159.195.64.135:4000"; 

  // Controllers
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late VideoPlayerController _videoController;

  // State
  List<dynamic> _messages = [];
  Timer? _refreshTimer;
  bool _isVideoInitialized = false;
  bool _isSending = false;

  // Style Colors
  final Color _glassBorder = Colors.white.withOpacity(0.2);
  final Color _bubbleMe = const Color(0xFF00FF94).withOpacity(0.2); // Hijau Neon
  final Color _bubbleOther = const Color(0xFFFFFFFF).withOpacity(0.1); // Putih Transparan

  @override
  void initState() {
    super.initState();
    _initVideo();
    _fetchMessages();
    
    // Auto Refresh Chat Setiap 2 Detik (Polling)
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchMessages();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  void _initVideo() {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse('https://k.top4top.io/m_3674ujj551.mp4'), // Background senada
    )..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
          _videoController.setVolume(0);
          _videoController.setLooping(true);
          _videoController.play();
        });
      });
  }

  // --- FUNGSI API ---

  Future<void> _fetchMessages() async {
    try {
      final res = await http.post(Uri.parse("$baseUrl/get-public-chat"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          List newMsgs = data['messages'];
          
          // Cek apakah ada pesan baru, jika ya scroll ke bawah
          bool shouldScroll = newMsgs.length > _messages.length;

          if (mounted) {
            setState(() {
              _messages = newMsgs;
            });
            
            if (shouldScroll) _scrollToBottom();
          }
        }
      }
    } catch (e) {
      // Silent error agar tidak mengganggu UI
    }
  }

  Future<void> _sendMessage() async {
    String text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    setState(() => _isSending = true);

    try {
      await http.post(
        Uri.parse("$baseUrl/send-public-chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": widget.username,
          "message": text,
        }),
      );
      await _fetchMessages(); // Refresh langsung
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengirim pesan", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Background Video
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

          // 2. Dark Overlay
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.7))),

          // 3. Main Content
          SafeArea(
            child: Column(
              children: [
                // HEADER
                _buildHeader(),

                // CHAT LIST
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['username'] == widget.username;
                      return _buildChatBubble(msg, isMe);
                    },
                  ),
                ),

                // INPUT AREA
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(bottom: BorderSide(color: _glassBorder)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("GLOBAL CHAT", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text("Live • ${_messages.length} messages", 
                        style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(dynamic msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Nama User (Jika bukan saya)
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 5, bottom: 2),
                child: Text(msg['username'], 
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            
            // Bubble Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? _bubbleMe : _bubbleOther,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(15),
                  topRight: const Radius.circular(15),
                  bottomLeft: Radius.circular(isMe ? 15 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 15),
                ),
                border: Border.all(
                  color: isMe ? Colors.greenAccent.withOpacity(0.3) : Colors.white10,
                  width: 1
                )
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg['message'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(msg['time'] ?? "", 
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9)),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            border: Border(top: BorderSide(color: _glassBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _glassBorder),
                  ),
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Type something...",
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isSending ? null : _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isSending ? Colors.grey : Colors.greenAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (!_isSending)
                        BoxShadow(color: Colors.greenAccent.withOpacity(0.4), blurRadius: 10, spreadRadius: 1)
                    ]
                  ),
                  child: Icon(
                    _isSending ? Icons.hourglass_top : Icons.send, 
                    color: Colors.black, size: 20
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}