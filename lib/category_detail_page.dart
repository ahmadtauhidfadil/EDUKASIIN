import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:edukasin/pages/detail_video_page.dart';
import 'package:edukasin/services/firestore_service.dart';

class CategoryDetailPage extends StatefulWidget {
  final Map<String, dynamic>? itemData;

  const CategoryDetailPage({super.key, this.itemData});

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  bool _isJoining = false;
  bool _isJoined = false;

  @override
  void initState() {
    super.initState();
    _checkJoinedStatus();
  }

  Future<void> _checkJoinedStatus() async {
    final item = widget.itemData;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (item == null || userId == null) return;

    final joined = await FirestoreService.isUserJoinedMinatBakatClass(item['id'].toString(), userId);
    if (!mounted) return;
    setState(() {
      _isJoined = joined;
    });
  }

  Future<void> _joinClass() async {
    final item = widget.itemData;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (item == null || userId == null || _isJoined) return;

    setState(() {
      _isJoining = true;
    });

    await FirestoreService.joinMinatBakatClass(item['id'].toString(), userId);
    await _checkJoinedStatus();

    if (!mounted) return;
    setState(() {
      _isJoining = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Berhasil terdaftar kelas.')),
    );
  }

  Future<void> _openModule(String fileUrl) async {
    if (fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modul belum tersedia atau belum diunggah.')),
      );
      return;
    }

    final uri = Uri.tryParse(fileUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL modul tidak valid.')),
      );
      return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka modul.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.itemData ?? {};
    final String title = data['title'] as String? ?? 'Bertani';
    final String description = data['description'] as String? ??
      'Bertani adalah kegiatan bercocok tanam yang menghasilkan berbagai komoditas pertanian. Cocok untuk Anda yang suka bekerja di luar ruangan dan berhubungan langsung dengan alam.';
    final String photoUrl = data['photoUrl'] as String? ??
      'https://images.unsplash.com/photo-1673252848144-46e11611527e?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';
    final String videoUrl = data['videoUrl'] as String? ?? '';
    final modulesRaw = data['modules'];
    final List<Map<String, dynamic>> modules = [];

    if (modulesRaw is List) {
      for (final module in modulesRaw) {
        if (module is Map<String, dynamic>) {
          modules.add({
            'name': module['name']?.toString() ?? 'Modul',
            'fileUrl': module['fileUrl']?.toString() ?? '',
          });
        } else if (module is String) {
          modules.add({'name': module, 'fileUrl': ''});
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'EdukasiIn',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        photoUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.yellow[700], shape: BoxShape.circle),
                          child: const Icon(Icons.grass, size: 16, color: Colors.white),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.play_arrow_outlined, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Video Pengenalan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: videoUrl.isEmpty
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailVideoPage(
                                    content: {
                                      'title': title,
                                      'description': description,
                                      'videoUrl': videoUrl,
                                      'photoUrl': photoUrl,
                                    },
                                  ),
                                ),
                              );
                            },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 150,
                              width: double.infinity,
                              color: Colors.grey.shade200,
                              child: videoUrl.isEmpty
                                  ? const Center(child: Icon(Icons.videocam_off, size: 48, color: Colors.grey))
                                  : Image.network(
                                      photoUrl,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: videoUrl.isEmpty ? Colors.grey.withOpacity(0.7) : const Color.fromRGBO(255, 255, 255, 0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              videoUrl.isEmpty ? Icons.block : Icons.play_arrow,
                              size: 36,
                              color: videoUrl.isEmpty ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (videoUrl.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text('Video belum tersedia untuk kelas ini.', style: TextStyle(color: Colors.grey)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: const [
                Icon(Icons.article_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text('Modul Pembelajaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                final module = modules[index];
                final hasFile = (module['fileUrl'] as String).isNotEmpty;
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
                      ),
                    ),
                    title: Text(module['name'] as String, style: const TextStyle(fontSize: 14)),
                    subtitle: hasFile ? null : const Text('Belum ada file modul', style: TextStyle(color: Colors.grey)),
                    trailing: Icon(Icons.chevron_right, color: hasFile ? Colors.blue : Colors.grey),
                    onTap: hasFile ? () => _openModule(module['fileUrl'] as String) : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.school),
                label: Text(_isJoined ? 'Sudah Ikut Kelas' : 'Ikuti Kelas'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isJoined || _isJoining ? null : _joinClass,
              ),
            ),
            if (_isJoined)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('Anda sudah terdaftar di kelas ini.', style: TextStyle(color: Colors.green)),
              ),
          ],
        ),
      ),
    );
  }
}
