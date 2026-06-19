import 'package:flutter/material.dart';
import 'package:edukasin/services/firestore_service.dart';
import 'detail_video_page.dart';
import 'enrolled_classes_page.dart';

class DashboardPage extends StatefulWidget {
  final String userId;

  const DashboardPage({super.key, required this.userId});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<List<Map<String, dynamic>>> _mentorContentsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _mentorContentsFuture =
        FirestoreService.getContents(status: 'approved');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── FIX: Helper untuk membaca field dengan fallback key alternatif ──
  // Firestore kadang menyimpan field dengan penamaan berbeda-beda
  // (camelCase vs snake_case vs nama lain). Fungsi ini mencoba semua
  // kemungkinan nama field sebelum fallback ke string kosong.
  String _getString(Map<String, dynamic> data, List<String> keys,
      {String fallback = ''}) {
    for (final key in keys) {
      final val = data[key];
      if (val != null && val is String && val.trim().isNotEmpty) {
        return val.trim();
      }
    }
    return fallback;
  }

  // ── FIX: Validasi URL sebelum dipakai ──
  bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _openVideo(BuildContext context, Map<String, dynamic> content) {
    // FIX: Coba semua kemungkinan nama field video di Firestore
    final videoUrl = _getString(content, [
      'videoUrl',
      'video_url',
      'video',
      'url',
      'contentUrl',
      'content_url',
    ]);


    if (!_isValidUrl(videoUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text('Konten ini belum memiliki video yang dapat diputar.'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailVideoPage(content: content),
      ),
    );
  }

  void _retryLoadContents() {
    setState(() {
      // FIX: Konsisten pakai status: 'approved' sama seperti initState
      _mentorContentsFuture =
          FirestoreService.getContents(status: 'approved');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          // ── HEADER ──
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'EdukasiIn',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Halo, Teman!',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white,
                          child:
                              Icon(Icons.person, color: Colors.blue, size: 28),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {
                      _searchQuery = value;
                    }),
                    decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.blue),
                      hintText: 'cari konten',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EnrolledClassesPage(userId: widget.userId),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 5)
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.book,
                                color: Colors.blue.shade600, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              'Kelas yang Diikuti',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue.shade900),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── CONTENT LIST ──
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Konten dari Mentor',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _mentorContentsFuture,
                      builder: (context, snapshot) {
                        // ── Loading ──
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        // ── Error ──
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline,
                                    size: 48,
                                    color: Colors.red.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'Terjadi kesalahan saat memuat konten',
                                  style: TextStyle(
                                      color: Colors.red.shade600,
                                      fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                // FIX: Tampilkan pesan error untuk debug
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32),
                                  child: Text(
                                    snapshot.error.toString(),
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12),
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  // FIX: Konsisten status: 'approved'
                                  onPressed: _retryLoadContents,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          );
                        }

                        final contents = snapshot.data ?? [];
                        final query = _searchQuery.trim().toLowerCase();
                        final filtered = query.isEmpty
                            ? contents
                            : contents.where((content) {
                                final title = _getString(content, [
                                  'title',
                                  'judul',
                                  'name',
                                  'className',
                                  'class_name'
                                ],
                                    fallback: '')
                                    .toLowerCase();
                                final mentor = _getString(content, [
                                  'mentorName',
                                  'mentor_name',
                                  'mentor',
                                ],
                                    fallback: '')
                                    .toLowerCase();
                                final desc = _getString(content, [
                                  'description',
                                  'desc',
                                  'detail'
                                ],
                                    fallback: '')
                                    .toLowerCase();
                                return title.contains(query) ||
                                    mentor.contains(query) ||
                                    desc.contains(query);
                              }).toList();

                        // ── Empty state ──
                        if (contents.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.video_library_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada konten dari mentor',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40),
                                  child: Text(
                                    'Mentor akan membagikan konten pembelajaran untuk Anda',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // ── List ──
                        return ListView.builder(
                          itemCount: filtered.length,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          itemBuilder: (context, index) {
                            final content = filtered[index];

                            // FIX: Pakai helper _getString dengan banyak
                            // fallback key agar tidak bergantung pada
                            // satu nama field tertentu
                            final thumbnail = _getString(content, [
                              'thumbnailUrl',
                              'thumbnail_url',
                              'thumbnail',
                              'photoUrl',
                              'photo_url',
                              'imageUrl',
                              'coverUrl',
                            ]);

                            final classTitle = _getString(
                              content,
                              ['title', 'judul', 'name', 'className'],
                              fallback: 'Konten Mentor',
                            );

                            final mentorName = _getString(
                              content,
                              [
                                'mentorName',
                                'mentor_name',
                                'mentor',
                                'instructorName',
                                'instructor',
                              ],
                              fallback: 'Mentor',
                            );

                            // FIX: Cek apakah ada videoUrl yang valid
                            // untuk menampilkan badge "Ada Video"
                            final videoUrl = _getString(content, [
                              'videoUrl',
                              'video_url',
                              'video',
                              'url',
                              'contentUrl',
                            ]);
                            final hasVideo = _isValidUrl(videoUrl);

                            return InkWell(
                              onTap: () => _openVideo(context, content),
                              borderRadius: BorderRadius.circular(20),
                              child: Card(
                                margin:
                                    const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(20)),
                                elevation: 2,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius:
                                          const BorderRadius.vertical(
                                              top: Radius.circular(20)),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          AspectRatio(
                                            aspectRatio: 16 / 9,
                                            child: thumbnail.isNotEmpty
                                                ? Image.network(
                                                    thumbnail,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    errorBuilder: (context,
                                                            error,
                                                            stackTrace) =>
                                                        Container(
                                                      color: Colors
                                                          .blue.shade50,
                                                      child: const Center(
                                                        child: Icon(
                                                            Icons
                                                                .video_library,
                                                            size: 40,
                                                            color:
                                                                Colors.blue),
                                                      ),
                                                    ),
                                                  )
                                                : Container(
                                                    color:
                                                        Colors.blue.shade50,
                                                    child: const Center(
                                                      child: Icon(
                                                          Icons
                                                              .video_library,
                                                          size: 40,
                                                          color: Colors.blue),
                                                    ),
                                                  ),
                                          ),
                                          // FIX: Icon play beda tampilan
                                          // jika tidak ada video
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: hasVideo
                                                  ? const Color.fromRGBO(255, 255, 255, 0.85)
                                                  : const Color.fromRGBO(0, 0, 0, 0.4),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              hasVideo
                                                  ? Icons.play_arrow
                                                  : Icons
                                                      .videocam_off_outlined,
                                              color: hasVideo
                                                  ? Colors.blue
                                                  : Colors.white54,
                                              size: 36,
                                            ),
                                          ),
                                          // FIX: Badge "Tidak tersedia"
                                          // jika videoUrl kosong/tidak valid
                                          if (!hasVideo)
                                            Positioned(
                                              top: 10,
                                              right: 10,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  'Video belum tersedia',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 16, 16, 20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            classTitle,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.person_outline_rounded,
                                                size: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  mentorName,
                                                  style: TextStyle(
                                                      color:
                                                          Colors.grey.shade700,
                                                      fontSize: 13),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                      },
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
