import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

// --- MUSIC MANAGER (SINGLETON) ---
// Class ini memisahkan logika musik dari UI agar musik tetap jalan
// meskipun halaman ditutup atau berpindah.
class MusicManager {
  static final MusicManager _instance = MusicManager._internal();
  factory MusicManager() => _instance;

  final AudioPlayer _player = AudioPlayer();
  
  // State Data
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  int currentIndex = 0;

  // Stream Controllers untuk update UI
  final StreamController<void> _stateController = StreamController.broadcast();
  Stream<void> get onStateChange => _stateController.stream;

  // Playlist Dummy (Ganti URL dengan link MP3 valid)
  final List<Map<String, String>> playlist = [
    {
      "title": "Losing Us",
      "artist": "Miyako Projects",
      "url": "https://h.top4top.io/m_3676ur8xh1.mp3",
    },
    {
      "title": "All Too Well",
      "artist": "Taylor Swift",
      "url": "https://e.top4top.io/m_3677ztoky1.mp3",
    },
    {
      "title": "Multo",
      "artist": "By Miyako Project",
      "url": "https://f.top4top.io/m_3677zy4vp1.mp3",
    },
  ];

  MusicManager._internal() {
    // Listener untuk update durasi & posisi
    _player.onPositionChanged.listen((p) {
      currentPosition = p;
      _stateController.add(null);
    });
    _player.onDurationChanged.listen((d) {
      totalDuration = d;
      _stateController.add(null);
    });
    _player.onPlayerStateChanged.listen((state) {
      isPlaying = state == PlayerState.playing;
      _stateController.add(null);
    });
    
    // Config agar jalan di background (Android/iOS)
    _player.setAudioContext(const AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
      ),
    ));
  }

  Map<String, String> get currentSong => playlist[currentIndex];

  Future<void> play() async {
    if (_player.state == PlayerState.paused) {
      await _player.resume();
    } else {
      await _player.play(UrlSource(currentSong['url']!));
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> next() async {
    currentIndex = (currentIndex + 1) % playlist.length;
    await _player.play(UrlSource(currentSong['url']!));
  }

  Future<void> prev() async {
    currentIndex = (currentIndex - 1 < 0) ? playlist.length - 1 : currentIndex - 1;
    await _player.play(UrlSource(currentSong['url']!));
  }

  Future<void> seek(double value) async {
    await _player.seek(Duration(seconds: value.toInt()));
  }
}

// --- HALAMAN UTAMA ---
class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  final MusicManager _musicManager = MusicManager();
  bool _isVideoInitialized = false;

  // Animasi Putar Piringan Hitam
  late AnimationController _rotationController;

  // Colors (Sama dengan AiChatPage)
  final Color _glassBorder = Colors.white.withOpacity(0.2);
  final Color _neonCyan = const Color(0xFF00E5FF);
  final Color _neonPurple = const Color(0xFFD500F9);

  @override
  void initState() {
    super.initState();
    _initVideo();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Jika musik sedang pause, hentikan animasi putar
    if (!_musicManager.isPlaying) {
      _rotationController.stop();
    }
  }

  void _initVideo() {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse('https://k.top4top.io/m_3674ujj551.mp4'), // Background Cyberpunk
    )..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
          _videoController.setVolume(0);
          _videoController.setLooping(true);
          _videoController.play();
        });
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

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
            child: StreamBuilder<void>(
              stream: _musicManager.onStateChange,
              builder: (context, snapshot) {
                // Atur animasi piringan berdasarkan status play
                if (_musicManager.isPlaying && !_rotationController.isAnimating) {
                  _rotationController.repeat();
                } else if (!_musicManager.isPlaying && _rotationController.isAnimating) {
                  _rotationController.stop();
                }

                return Column(
                  children: [
                    // HEADER
                    _buildHeader(),

                    const Spacer(),

                    // ALBUM ART (ROTATING)
                    _buildAlbumArt(),

                    const Spacer(),

                    // INFO & CONTROLS
                    _buildPlayerControls(),
                    
                    const SizedBox(height: 30),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: _glassBorder),
              ),
              child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            ),
          ),
          const Spacer(),
          Text(
            "NOW PLAYING",
            style: TextStyle(
              color: _neonCyan,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 2,
              shadows: [Shadow(color: _neonCyan, blurRadius: 10)],
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40), // Dummy balance
        ],
      ),
    );
  }

  Widget _buildAlbumArt() {
    return RotationTransition(
      turns: _rotationController,
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [_neonPurple.withOpacity(0.5), _neonCyan.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: _neonPurple.withOpacity(0.4), blurRadius: 30, spreadRadius: 5),
            BoxShadow(color: _neonCyan.withOpacity(0.4), blurRadius: 30, spreadRadius: 5),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: const Icon(Icons.music_note, color: Colors.white, size: 50),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerControls() {
    final song = _musicManager.currentSong;
    final position = _musicManager.currentPosition;
    final duration = _musicManager.totalDuration;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _glassBorder),
          ),
          child: Column(
            children: [
              // Song Title & Artist
              Text(
                song['title']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                song['artist']!,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 25),

              // Progress Bar
              Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor: _neonPurple,
                      inactiveTrackColor: Colors.white12,
                      thumbColor: _neonCyan,
                      overlayColor: _neonCyan.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble()),
                      max: duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1,
                      onChanged: (value) {
                        _musicManager.seek(value);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        Text(_formatDuration(duration), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 35),
                    onPressed: () => _musicManager.prev(),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_musicManager.isPlaying) {
                        _musicManager.pause();
                      } else {
                        _musicManager.play();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [_neonCyan, _neonPurple]),
                        boxShadow: [
                          BoxShadow(color: _neonPurple.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)
                        ],
                      ),
                      child: Icon(
                        _musicManager.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 35),
                    onPressed: () => _musicManager.next(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}