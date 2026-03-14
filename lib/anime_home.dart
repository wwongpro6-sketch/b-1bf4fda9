import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// --- CONFIG & THEME (FURINA HYDRO THEME) ---
const String jikanBaseUrl = "https://api.jikan.moe/v4";
const String videoSearchApi = "https://api.siputzx.my.id/api/s/youtube";

// Palette Warna (Biru Furina - Genshin Impact)
final Color deepBlue = const Color(0xFF1A237E);   // Dark Indigo/Navy (Ousia)
final Color mainBlue = const Color(0xFF2979FF);   // Royal Blue (Primary)
final Color accentAqua = const Color(0xFF00E5FF); // Cyan/Hydro Vision (Pneuma)
final Color bgDark = const Color(0xFF050510);     // Deep Abyss/Space Blue
final Color cardDark = const Color(0xFF101626);   // Dark Slate Blue for Cards

// --- MODEL ---
class Anime {
  final int malId;
  final String title;
  final String imageUrl;
  final double? score;
  final String? type;
  final int? year;
  final int? episodes;
  final String? status;
  final String? synopsis;
  final List<String> genres;
  final String? trailerUrl;

  Anime({
    required this.malId,
    required this.title,
    required this.imageUrl,
    this.score,
    this.type,
    this.year,
    this.episodes,
    this.status,
    this.synopsis,
    required this.genres,
    this.trailerUrl,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      malId: json['mal_id'],
      title: json['title'] ?? 'No Title',
      imageUrl: json['images']['jpg']['large_image_url'] ?? '',
      score: json['score']?.toDouble(),
      type: json['type'],
      year: json['year'],
      episodes: json['episodes'],
      status: json['status'],
      synopsis: json['synopsis'],
      genres: (json['genres'] as List?)?.map((e) => e['name'].toString()).toList() ?? [],
      trailerUrl: json['trailer']?['youtube_id'], // Added safe navigation
    );
  }
}

// ==========================================
// 1. HOME PAGE
// ==========================================
class HomeAnimePage extends StatefulWidget {
  const HomeAnimePage({super.key});

  @override
  State<HomeAnimePage> createState() => _HomeAnimePageState();
}

class _HomeAnimePageState extends State<HomeAnimePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Anime> _animeList = [];
  bool _isLoading = true;
  String _activeCategory = "Top Airing";

  final List<String> _categories = ["Top Airing", "Upcoming", "Popular", "Action", "Romance", "Drama", "Fantasy"];

  @override
  void initState() {
    super.initState();
    _fetchAnime();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAnime({String? query}) async {
    setState(() => _isLoading = true);
    try {
      String url;
      if (query != null && query.isNotEmpty) {
        url = "$jikanBaseUrl/anime?q=$query&sfw=true&page=1&limit=20";
      } else {
        String filter = "bypopularity";
        if (_activeCategory == "Top Airing") filter = "airing";
        if (_activeCategory == "Upcoming") filter = "upcoming";
        
        url = "$jikanBaseUrl/top/anime?filter=$filter&page=1&limit=20";
      }

      final response = await http.get(Uri.parse(url));
      
      if (!mounted) return; // Prevent setState if widget is disposed

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        setState(() {
          _animeList = data.map((e) => Anime.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching anime: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.black, deepBlue.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: mainBlue.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(color: deepBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("ANIME STATION", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
                        SizedBox(height: 5),
                        Text("Stream Unlimited Anime", style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.movie_filter_rounded, color: accentAqua, size: 40),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: mainBlue.withOpacity(0.1), blurRadius: 10)],
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: accentAqua,
                  decoration: InputDecoration(
                    hintText: "Search anime...",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(Icons.search, color: mainBlue),
                    filled: true,
                    fillColor: cardDark,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: mainBlue.withOpacity(0.3))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: accentAqua, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  ),
                  onSubmitted: (val) => _fetchAnime(query: val),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Category Chips
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isActive = _activeCategory == cat;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _activeCategory = cat;
                        _searchController.clear();
                      });
                      _fetchAnime();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? mainBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isActive ? accentAqua : Colors.white24),
                        boxShadow: isActive ? [BoxShadow(color: deepBlue, blurRadius: 8)] : [],
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Grid Anime
            Expanded(
              child: _isLoading
                  ? _buildShimmerGrid()
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: _animeList.length,
                      itemBuilder: (context, index) {
                        final anime = _animeList[index];
                        return _buildAnimeCard(anime);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimeCard(Anime anime) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => AnimeDetailPage(anime: anime)));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: mainBlue.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 5)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: anime.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: cardDark),
                  errorWidget: (context, url, error) => Container(color: cardDark, child: const Icon(Icons.error, color: Colors.white)),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.95)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              if (anime.score != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: deepBlue.withOpacity(0.8), borderRadius: BorderRadius.circular(10), border: Border.all(color: accentAqua.withOpacity(0.5))),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 10, color: Colors.yellow),
                        const SizedBox(width: 4),
                        Text(anime.score.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(anime.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text("${anime.type ?? 'TV'} • ${anime.year ?? '?'}", style: TextStyle(color: accentAqua, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return Shimmer.fromColors(
      baseColor: cardDark,
      highlightColor: deepBlue.withOpacity(0.4),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Container(decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15))),
      ),
    );
  }
}

// ==========================================
// 2. DETAIL PAGE (Info & Trailer)
// ==========================================
class AnimeDetailPage extends StatefulWidget {
  final Anime anime;
  const AnimeDetailPage({super.key, required this.anime});

  @override
  State<AnimeDetailPage> createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<AnimeDetailPage> {
  YoutubePlayerController? _trailerController;

  @override
  void initState() {
    super.initState();
    if (widget.anime.trailerUrl != null) {
      _trailerController = YoutubePlayerController(
        initialVideoId: widget.anime.trailerUrl!,
        flags: const YoutubePlayerFlags(autoPlay: false, mute: false, forceHD: true),
      );
    }
  }

  @override
  void dispose() {
    _trailerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 450,
            backgroundColor: bgDark,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(50), border: Border.all(color: mainBlue)),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(imageUrl: widget.anime.imageUrl, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [bgDark, Colors.transparent, bgDark],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.anime.title,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: widget.anime.genres.take(3).map((g) => 
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: deepBlue.withOpacity(0.5), 
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: accentAqua)
                              ),
                              child: Text(g, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          ).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("SYNOPSIS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  Text(
                    widget.anime.synopsis ?? "No synopsis available.",
                    style: const TextStyle(color: Colors.white60, height: 1.5),
                  ),
                  const SizedBox(height: 30),

                  if (_trailerController != null) ...[
                    const Text("TRAILER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 15),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: mainBlue.withOpacity(0.5)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: YoutubePlayer(
                          controller: _trailerController!,
                          showVideoProgressIndicator: true,
                          progressIndicatorColor: accentAqua,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],

                  // WATCH NOW BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AnimeStreamPage(anime: widget.anime),
                          ),
                        );
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [deepBlue, accentAqua]),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(color: mainBlue.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))
                          ]
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_circle_fill, size: 28, color: Colors.white),
                              SizedBox(width: 10),
                              Text("WATCH EPISODES", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. STREAMING PAGE (Updated with Better Search)
// ==========================================
class AnimeStreamPage extends StatefulWidget {
  final Anime anime;
  const AnimeStreamPage({super.key, required this.anime});

  @override
  State<AnimeStreamPage> createState() => _AnimeStreamPageState();
}

class _AnimeStreamPageState extends State<AnimeStreamPage> {
  YoutubePlayerController? _ytController;
  bool _isSearching = true;
  String? _errorMsg;
  int _currentEpisode = 1;
  int _totalEpisodes = 24;

  @override
  void initState() {
    super.initState();
    _totalEpisodes = widget.anime.episodes ?? 24;
    if (_totalEpisodes > 200) _totalEpisodes = 200; 
    _searchVideo();
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  Future<void> _searchVideo() async {
    if (mounted) {
      setState(() {
        _isSearching = true;
        _errorMsg = null;
        _ytController?.pause();
      });
    }
    
    // --- QUERY VARIATIONS ---
    final queries = [
      "${widget.anime.title} Episode $_currentEpisode Subtitle Indonesia",
      "${widget.anime.title} Episode $_currentEpisode Sub Indo",
      "${widget.anime.title} Episode $_currentEpisode",
      "${widget.anime.title} Ep $_currentEpisode",
      "${widget.anime.title} Episode $_currentEpisode Eng Sub",
    ];

    bool found = false;

    for (String query in queries) {
      if (found) break;

      try {
        debugPrint("🔍 Searching: $query");

        final response = await http.post(
          Uri.parse(videoSearchApi),
          body: jsonEncode({"query": query}),
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          if (data['data'] != null && (data['data'] as List).isNotEmpty) {
            var firstResult = data['data'][0];
            
            String? videoId;
            if (firstResult['videoId'] != null) {
              videoId = firstResult['videoId'];
            } else if (firstResult['id'] != null) {
              videoId = firstResult['id'];
            } else if (firstResult['url'] != null) {
              videoId = YoutubePlayer.convertUrlToId(firstResult['url']);
            }

            if (videoId != null && videoId.isNotEmpty) {
              _initPlayer(videoId);
              found = true;
            }
          }
        }
      } catch (e) {
        debugPrint("❌ Error searching query '$query': $e");
      }
    }

    if (mounted) {
      if (!found) {
        setState(() {
          _isSearching = false;
          _errorMsg = "Episode $_currentEpisode tidak ditemukan di YouTube.\nMungkin terkena Copyright.";
        });
      } else {
        setState(() {
          _isSearching = false;
          _errorMsg = null;
        });
      }
    }
  }

  void _initPlayer(String videoId) {
    if (_ytController != null) {
      _ytController!.load(videoId);
    } else {
      _ytController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          forceHD: true,
          enableCaption: true,
          hideControls: false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // --- VIDEO PLAYER CONTAINER ---
            Container(
              height: 250, 
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isSearching)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: accentAqua),
                        const SizedBox(height: 10),
                        const Text("Searching video...", style: TextStyle(color: Colors.white54, fontSize: 12))
                      ],
                    )
                  else if (_errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: accentAqua, size: 40),
                          const SizedBox(height: 10),
                          Text(_errorMsg!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    )
                  else
                    YoutubePlayer(
                      controller: _ytController!,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: accentAqua,
                      progressColors: ProgressBarColors(
                        playedColor: accentAqua,
                        handleColor: accentAqua,
                        backgroundColor: Colors.white24,
                        bufferedColor: Colors.white10
                      ),
                    ),
                  
                  // Tombol Back Custom
                  Positioned(
                    top: 10,
                    left: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- EPISODE GRID & STATS ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "EPISODE $_currentEpisode",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Orbitron'),
                    ),
                    Text(widget.anime.title, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                    
                    const SizedBox(height: 20),

                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem(Icons.remove_red_eye, "1.2M"),
                        _statItem(Icons.thumb_up, "85K"),
                        _statItem(Icons.trending_up, "#3 Trending"),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 10),

                    // Grid Episodes
                    const Text("ALL EPISODES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _totalEpisodes,
                      itemBuilder: (context, index) {
                        final epNum = index + 1;
                        final isSelected = epNum == _currentEpisode;
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? mainBlue : cardDark, // Selected Blue
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: isSelected ? accentAqua : Colors.white24)
                            ),
                          ),
                          onPressed: () {
                            if (!isSelected) {
                              setState(() => _currentEpisode = epNum);
                              _searchVideo();
                            }
                          },
                          child: Text("$epNum"),
                        );
                      },
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: accentAqua, size: 20),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}