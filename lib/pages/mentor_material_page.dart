import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'minat_bakat_detail_page.dart';

class MentorMaterialPage extends StatefulWidget {
  const MentorMaterialPage({super.key});

  @override
  State<MentorMaterialPage> createState() => _MentorMaterialPageState();
}

class _MentorMaterialPageState extends State<MentorMaterialPage> {
  String _query = '';
  Future<List<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    _future = FirestoreService.getMinatBakatItems(query: _query);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('Materi & Kelas', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Kelola materi pembelajaran, berikan arahan, dan atur kelas online/Zoom.', style: TextStyle(fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'cari konten...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                  onChanged: (v) {
                    _query = v;
                    _loadItems();
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    final items = snap.data ?? [];
                    if (items.isEmpty) return const Center(child: Text('Belum ada minat & bakat.'));

                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 120),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final title = item['title'] ?? '';
                        final photo = item['photoUrl']?.toString();
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MinatBakatDetailPage(item: item),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: photo != null && photo.isNotEmpty
                                      ? Image.network(photo, fit: BoxFit.cover)
                                      : Container(color: Colors.grey.shade200),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.35)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
    );
  }
}
