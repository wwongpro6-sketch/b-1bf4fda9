import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser; // Import package HTML
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- MAIN PAGE (KOMIK HOME) ---
class HomeKomikPage extends StatefulWidget {
  const HomeKomikPage({super.key});

  @override
  State<HomeKomikPage> createState() => _HomeKomikPageState();
}

class _HomeKomikPageState extends State<HomeKomikPage> {
  Map<String, dynamic>? komikData;
  bool isLoading = true;
  bool isSearching = false;
  List<dynamic> searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  // --- PALETTE WARNA NEON ---
  final Color primaryPurple = const Color(0xFFD500F9);
  final Color primaryPink = const Color(0xFFFF4081);
  final Color primaryCyan = const Color(0xFF00E5FF);

  // --- DATA MANUAL (RECOMMENDED) ---
  final List<Map<String, String>> recommendedKomiks = [
    {
      'title': 'One Piece',
      'poster': 'https://komiku.org/wp-content/uploads/2021/04/Komik-One-Piece.jpg', // URL Gambar estimasi
      'link': 'https://komiku.org/manga/one-piece/',
      'type': 'Manga'
    },
    {
      'title': 'Naruto Shippuden',
      'poster': 'https://komiku.org/wp-content/uploads/2021/04/Komik-Naruto.jpg',
      'link': 'https://komiku.org/manga/naruto/',
      'type': 'Manga'
    },
    {
      'title': 'Solo Leveling',
      'poster': 'https://komiku.org/wp-content/uploads/2021/04/Komik-Solo-Leveling.jpg',
      'link': 'https://komiku.org/manhwa/solo-leveling/',
      'type': 'Manhwa'
    },
    {
      'title': 'Kimetsu no Yaiba',
      'poster': 'https://komiku.org/wp-content/uploads/2021/04/Komik-Kimetsu-no-Yaiba.jpg',
      'link': 'https://komiku.org/manga/kimetsu-no-yaiba/',
      'type': 'Manga'
    },
    {
      'title': 'Iron Ladies',
      'poster': 'https://komiku.org/wp-content/uploads/2021/04/Komik-Iron-Ladies.jpg',
      'link': 'https://komiku.org/manhua/iron-ladies/',
      'type': 'Manhua'
    },
    {
      'title': 'Crimson Karma',
      'poster': 'https://komiku.org/wp-content/uploads/2021/04/Komik-Crimson-Karma.jpg', // Placeholder
      'link': 'https://komiku.org/manhwa/crimson-karma/',
      'type': 'Manhwa'
    },
    {
      'title': 'Boruto',
      'poster': 'https://komiku.org/wp-content/uploads/2021/04/Komik-Boruto.jpg',
      'link': 'https://komiku.org/manga/boruto/',
      'type': 'Manga'
    },
    {
      'title': 'Jujutsu Kaisen',
      'poster': 'https://komiku.org/wp-content/uploads/2021/04/Komik-Jujutsu-Kaisen.jpg',
      'link': 'https://komiku.org/manga/jujutsu-kaisen/',
      'type': 'Manga'
    },
    {
      'title': 'Black Clover',
      'poster': 'https://komiku.org/wp-content/uploads/2021/04/Komik-Black-Clover.jpg',
      'link': 'https://komiku.org/manga/black-clover/',
      'type': 'Manga'
    },
    {
      'title': 'Bleach',
      'poster': 'https://komiku.org/wp-content/uploads/2021/04/Komik-Bleach.jpg',
      'link': 'https://komiku.org/manga/bleach/',
      'type': 'Manga'
    },
  ];

  @override
  void initState() {
    super.initState();
    fetchKomikuData();
  }

  // --- SCRAPING LOGIC KOMIKU.ORG ---
  Future<void> fetchKomikuData() async {
    try {
      final response = await http.get(Uri.parse('https://komiku.org/'));

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);

        // 1. Ambil Data Populer (Slider/Hot)
        List<Map<String, dynamic>> populerList = [];
        var populerElements = document.querySelectorAll('.bge'); 
        
        for (var i = 0; i < 5 && i < populerElements.length; i++) {
            var el = populerElements[i];
            var titleEl = el.querySelector('h3');
            var imgEl = el.querySelector('img');
            var linkEl = el.querySelector('a');
            var typeEl = el.querySelector('.tpe1_inf');

            if (titleEl != null && imgEl != null && linkEl != null) {
              populerList.add({
                'title': titleEl.text.trim(),
                'poster': imgEl.attributes['src']?.replaceAll('?resize=450,235', '') ?? '',
                'link': "https://komiku.org${linkEl.attributes['href']}",
                'type': typeEl?.text.trim() ?? 'Manga',
                'desc': el.querySelector('p')?.text.trim() ?? 'No description',
              });
            }
        }

        // 2. Ambil Data Terbaru
        List<Map<String, dynamic>> terbaruList = [];
        for (var i = 5; i < populerElements.length && i < 20; i++) {
           var el = populerElements[i];
           var titleEl = el.querySelector('h3');
           var imgEl = el.querySelector('img');
           var linkEl = el.querySelector('a');
           var chapterEl = el.querySelector('.new1');

           if (titleEl != null && imgEl != null && linkEl != null) {
              terbaruList.add({
                'title': titleEl.text.trim(),
                'poster': imgEl.attributes['src']?.replaceAll('?resize=450,235', '') ?? '',
                'link': "https://komiku.org${linkEl.attributes['href']}",
                'last_chapter': chapterEl?.text.trim() ?? 'Baru',
                'type': el.querySelector('.tpe1_inf')?.text.trim() ?? 'Komik',
              });
           }
        }

        if (mounted) {
          setState(() {
            komikData = {
              'populer': populerList,
              'terbaru': terbaruList,
            };
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load Komiku');
      }
    } catch (e) {
      debugPrint('Scraping Error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- SEARCH LOGIC ---
  Future<void> searchKomik(String query) async {
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
        searchResults.clear();
      });
      return;
    }

    setState(() => isSearching = true);

    try {
      final url = 'https://data.komiku.id/cari/?post_type=manga&s=${Uri.encodeComponent(query)}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        var results = document.querySelectorAll('.bge');
        List<Map<String, dynamic>> tempRes = [];

        for (var el in results) {
           var titleEl = el.querySelector('h3');
           var imgEl = el.querySelector('img');
           var linkEl = el.querySelector('a');
           
           if (titleEl != null && linkEl != null) {
             tempRes.add({
               'title': titleEl.text.trim(),
               'poster': imgEl?.attributes['src'] ?? 'https://via.placeholder.com/150',
               'link': linkEl.attributes['href']!.startsWith('http') 
                  ? linkEl.attributes['href'] 
                  : "https://komiku.org${linkEl.attributes['href']}",
               'type': el.querySelector('.tpe1_inf')?.text.trim() ?? 'Komik',
               'desc': el.querySelector('p')?.text.trim() ?? '',
             });
           }
        }

        setState(() {
          searchResults = tempRes;
        });
      }
    } catch (e) {
      debugPrint('Search Error: $e');
      setState(() => searchResults = []);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      isSearching = false;
      searchResults.clear();
    });
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: "Cari Manga, Manhwa, Manhua...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: primaryCyan),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: primaryCyan.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: primaryCyan),
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _searchFocusNode.unfocus();
                  searchKomik(value.trim());
                }
              },
            ),
          ),

          // Content
          Expanded(
            child: isLoading
                ? _buildLoadingShimmer()
                : isSearching
                    ? _buildSearchResults()
                    : komikData == null
                        ? _buildErrorWidget()
                        : _buildKomikContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildKomikContent() {
    return RefreshIndicator(
      onRefresh: fetchKomikuData,
      color: primaryCyan,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Access Categories
             _buildSectionHeader(Icons.public, "Kategori"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildQuickAccessCard("Manga", Icons.menu_book, const Color(0xFFE53935), "https://komiku.org/manga/")),
                const SizedBox(width: 8),
                Expanded(child: _buildQuickAccessCard("Manhwa", Icons.phone_android, const Color(0xFF43A047), "https://komiku.org/manhwa/")),
                const SizedBox(width: 8),
                Expanded(child: _buildQuickAccessCard("Manhua", Icons.brush, const Color(0xFF1E88E5), "https://komiku.org/manhua/")),
              ],
            ),
            const SizedBox(height: 24),

            // === BAGIAN BARU: REKOMENDASI MANUAL (TOP 10) ===
            _buildSectionHeader(Icons.recommend, "Komik Legendaris & Populer"),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recommendedKomiks.length,
                itemBuilder: (context, index) {
                  final item = recommendedKomiks[index];
                  // Convert Map<String, String> to dynamic for compatibility
                  return _buildHotCard({
                    'title': item['title'],
                    'poster': item['poster'],
                    'link': item['link'],
                    'type': item['type'],
                    'desc': 'Komik Pilihan'
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // Populer (Scraped)
            _buildSectionHeader(Icons.local_fire_department, "Sedang Panas (Minggu Ini)"),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: komikData!['populer'].length,
                itemBuilder: (context, index) {
                  return _buildHotCard(komikData!['populer'][index]);
                },
              ),
            ),
            const SizedBox(height: 24),

            // Terbaru (Updates)
            _buildSectionHeader(Icons.update, "Rilis Terbaru"),
            const SizedBox(height: 12),
            _buildKomikGrid(komikData!['terbaru']),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: primaryCyan, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildHotCard(Map<String, dynamic> komik) {
    return GestureDetector(
      onTap: () => _openKomik(komik),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
          color: Colors.white.withOpacity(0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  komik['poster'] ?? '',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // Placeholder jika gambar error/tidak ada
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[800],
                    child: const Center(child: Icon(Icons.image_not_supported, color: Colors.white54)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    komik['type'] ?? 'Komik',
                    style: TextStyle(color: primaryPink, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    komik['title'] ?? 'No Title',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKomikGrid(List<dynamic> list) {
    return GridView.builder(
      itemCount: list.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 260,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final komik = list[index];
        return GestureDetector(
          onTap: () => _openKomik(komik),
          child: Container(
            decoration: BoxDecoration(
               color: Colors.white.withOpacity(0.02),
               borderRadius: BorderRadius.circular(12),
               border: Border.all(color: Colors.white.withOpacity(0.05))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          komik['poster'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.white10),
                        ),
                        // Type Badge
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: primaryCyan.withOpacity(0.5)),
                            ),
                            child: Text(
                              komik['type'],
                              style: TextStyle(color: primaryCyan, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        komik['title'],
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.history_toggle_off, color: primaryPurple, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              komik['last_chapter'] ?? 'Update',
                              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (searchResults.isEmpty) {
      return const Center(child: Text("Komik tidak ditemukan", style: TextStyle(color: Colors.white)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final komik = searchResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(komik['poster'], width: 50, height: 80, fit: BoxFit.cover,
                errorBuilder: (_,__,___) => Container(color:Colors.grey, width: 50, height: 80),
              ),
            ),
            title: Text(komik['title'], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(komik['type'], style: TextStyle(color: primaryCyan, fontSize: 11)),
                const SizedBox(height: 2),
                Text(komik['desc'], style: const TextStyle(color: Colors.grey, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
            onTap: () => _openKomik(komik),
          ),
        );
      },
    );
  }

  Widget _buildQuickAccessCard(String title, IconData icon, Color color, String url) {
    return InkWell(
      onTap: () {
         Navigator.push(context, MaterialPageRoute(builder: (_) => KomikWebView(url: url, title: title)));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, color: Colors.white54, size: 50),
          const SizedBox(height: 10),
          const Text("Gagal memuat data", style: TextStyle(color: Colors.white)),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
            onPressed: fetchKomikuData,
            child: const Text("Coba Lagi", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openKomik(Map<String, dynamic> komik) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KomikDetailPage(komikData: komik),
      ),
    );
  }
}

// --- KOMIK DETAIL PAGE ---
class KomikDetailPage extends StatelessWidget {
  final Map<String, dynamic> komikData;

  const KomikDetailPage({super.key, required this.komikData});

  @override
  Widget build(BuildContext context) {
    final Color primaryCyan = const Color(0xFF00E5FF);
    final Color primaryPurple = const Color(0xFFD500F9);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            backgroundColor: const Color(0xFF050505),
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    komikData['poster'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF050505).withOpacity(0.8),
                          const Color(0xFF050505),
                        ],
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryCyan,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            komikData['type'] ?? 'Komik',
                            style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          komikData['title'] ?? 'No Title',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                          ),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Read Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [primaryCyan, primaryPurple]),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(color: primaryCyan.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: () {
                         Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => KomikWebView(url: komikData['link'], title: komikData['title']),
                            ),
                          );
                      },
                      icon: const Icon(Icons.menu_book, color: Colors.black),
                      label: const Text("BACA SEKARANG", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text("Deskripsi", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    komikData['desc'] ?? "Silahkan klik tombol baca untuk melihat detail lengkap dan chapter di website Komiku.",
                    style: TextStyle(color: Colors.grey[400], height: 1.5),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WEBVIEW (SAMA DENGAN ANIME TAPI KHUSUS KOMIK) ---
class KomikWebView extends StatefulWidget {
  final String url;
  final String? title;

  const KomikWebView({super.key, required this.url, this.title});

  @override
  State<KomikWebView> createState() => _KomikWebViewState();
}

class _KomikWebViewState extends State<KomikWebView> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if(mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
             // Injeksi CSS untuk menghilangkan iklan/header mengganggu di Komiku (Opsional)
             _controller.runJavaScript("document.getElementsByClassName('header')[0].style.display='none';");
            if(mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title ?? "Komiku", style: const TextStyle(color: Colors.white, fontSize: 14)),
            const Text("Source: komiku.org", style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
        ],
      ),
    );
  }
}