import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

// ==========================================
// HALAMAN 1: LIST USER (DARI keyList.json)
// ==========================================
class PrivateUserListPage extends StatefulWidget {
  final String myUsername;
  const PrivateUserListPage({super.key, required this.myUsername});

  @override
  State<PrivateUserListPage> createState() => _PrivateUserListPageState();
}

class _PrivateUserListPageState extends State<PrivateUserListPage> {
  // Ganti dengan URL server Anda
  final String baseUrl = "http://159.195.64.135:4000";
  
  List<dynamic> _users = [];
  bool _isLoading = true;

  // Warna Tema (Senada dengan Dashboard)
  final Color deepRed = const Color(0xFF8B0000);
  final Color mainRed = const Color(0xFFB71C1C);
  final Color bgBlack = const Color(0xFF000000);

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final res = await http.post(Uri.parse("$baseUrl/get-all-users"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            // Filter: Jangan tampilkan username sendiri di list
            _users = (data['users'] as List)
                .where((u) => u['username'] != widget.myUsername)
                .toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text("Private Messages", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 1)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: mainRed, height: 1),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: mainRed))
          : _users.isEmpty
              ? const Center(child: Text("No active users found.", style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return _buildUserCard(user);
                  },
                ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    String role = user['role'] ?? 'User';
    String username = user['username'] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF111111), const Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mainRed.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: deepRed.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Masuk ke Room Chat
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PrivateChatRoomPage(
                  myUsername: widget.myUsername,
                  targetUsername: username,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            child: Row(
              children: [
                // Avatar Huruf Depan
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: mainRed.withOpacity(0.1),
                    border: Border.all(color: mainRed.withOpacity(0.5)),
                  ),
                  child: Center(
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : "?",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // Info User
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: mainRed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chat_bubble_outline, color: mainRed),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// HALAMAN 2: CHAT ROOM (RUANG CHAT)
// ==========================================
class PrivateChatRoomPage extends StatefulWidget {
  final String myUsername;
  final String targetUsername;

  const PrivateChatRoomPage({
    super.key,
    required this.myUsername,
    required this.targetUsername,
  });

  @override
  State<PrivateChatRoomPage> createState() => _PrivateChatRoomPageState();
}

class _PrivateChatRoomPageState extends State<PrivateChatRoomPage> {
  final String baseUrl = "http://159.195.64.135:4000";
  
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late VideoPlayerController _videoController;

  List<dynamic> _messages = [];
  Timer? _refreshTimer;
  bool _isVideoInitialized = false;
  bool _isSending = false;

  // Colors
  final Color _glassBorder = Colors.white.withOpacity(0.2);
  final Color _bubbleMe = const Color(0xFFB71C1C).withOpacity(0.6); // Merah Transparan
  final Color _bubbleOther = const Color(0xFF333333).withOpacity(0.6); // Abu Gelap

  @override
  void initState() {
    super.initState();
    _initVideo();
    _fetchPrivateMessages();
    
    // Auto Refresh Chat Private setiap 2 detik
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchPrivateMessages();
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
      Uri.parse('https://k.top4top.io/m_3674ujj551.mp4'),
    )..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
          _videoController.setVolume(0);
          _videoController.setLooping(true);
          _videoController.play();
        });
      });
  }

  // --- API CALLS ---

  Future<void> _fetchPrivateMessages() async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/get-private-chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user1": widget.myUsername,
          "user2": widget.targetUsername,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          List newMsgs = data['messages'];
          // Cek jika ada pesan baru untuk auto scroll
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
      // Silent error
    }
  }

  Future<void> _sendPrivateMessage() async {
    String text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    setState(() => _isSending = true);

    try {
      await http.post(
        Uri.parse("$baseUrl/send-private-chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender": widget.myUsername,
          "receiver": widget.targetUsername,
          "message": text,
        }),
      );
      await _fetchPrivateMessages();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengirim pesan"), backgroundColor: Colors.red),
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

          // 3. Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender'] == widget.myUsername;
                      return _buildChatBubble(msg, isMe);
                    },
                  ),
                ),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(bottom: BorderSide(color: _glassBorder)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              CircleAvatar(
                backgroundColor: const Color(0xFFB71C1C), // Main Red
                radius: 18,
                child: Text(
                  widget.targetUsername.isNotEmpty ? widget.targetUsername[0].toUpperCase() : "?", 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.targetUsername, 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      const Text("Private Chat", style: TextStyle(color: Colors.white54, fontSize: 10)),
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
            color: isMe ? Colors.redAccent.withOpacity(0.5) : Colors.white10,
            width: 1
          ),
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
                      hintText: "Message...",
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendPrivateMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isSending ? null : _sendPrivateMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isSending ? Colors.grey : const Color(0xFFB71C1C),
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (!_isSending)
                        BoxShadow(color: const Color(0xFFB71C1C).withOpacity(0.4), blurRadius: 10, spreadRadius: 1)
                    ]
                  ),
                  child: Icon(
                    _isSending ? Icons.hourglass_top : Icons.send, 
                    color: Colors.white, size: 20
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