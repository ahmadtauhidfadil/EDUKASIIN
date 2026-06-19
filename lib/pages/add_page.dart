import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'discussion_detail_page.dart';

class AddPage extends StatefulWidget {
  final String userId;
  final String userName;

  const AddPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final TextEditingController _discussionTitleController = TextEditingController();
  final TextEditingController _discussionMessageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _discussionTitleController.dispose();
    _discussionMessageController.dispose();
    super.dispose();
  }

  void _submitDiscussion() async {
    final title = _discussionTitleController.text.trim();
    final message = _discussionMessageController.text.trim();
    
    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan isi diskusi harus diisi.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirestoreService.createDiscussion(
        widget.userId,
        widget.userName,
        title,
        message,
      );

      if (mounted) {
        _discussionTitleController.clear();
        _discussionMessageController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diskusi berhasil dibuat.')),
        );

        // Refresh discussions list by rebuilding
        setState(() {
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inSeconds < 60) {
        return 'Baru saja';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} menit lalu';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} jam lalu';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari lalu';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
    return 'Baru saja';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Diskusi & Tanya Jawab',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ajukan topik diskusi baru untuk bertanya atau berbagi materi dengan komunitas.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _discussionTitleController,
            decoration: InputDecoration(
              labelText: 'Judul Diskusi',
              hintText: 'Masukkan topik diskusi',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _discussionMessageController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Isi Diskusi',
              hintText: 'Jelaskan pertanyaan atau topik yang ingin dibahas',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitDiscussion,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kirim Diskusi'),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService.streamDiscussions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final discussions = snapshot.data ?? [];
                final userDiscussions = discussions.where((d) => d['userId'] == widget.userId).toList();

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const Text('Diskusi Kamu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (userDiscussions.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Belum ada diskusi milikmu. Tambahkan topik baru di atas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...userDiscussions.map((discussion) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        discussion['title'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    PopupMenuButton(
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          child: const Text('Hapus'),
                                          onTap: () async {
                                            await FirestoreService.deleteDiscussion(discussion['id']);
                                            if (mounted) {
                                              setState(() {});
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Diskusi berhasil dihapus.')),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  discussion['message'] ?? '',
                                  style: const TextStyle(color: Colors.black87),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _formatTime(discussion['createdAt']),
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    const SizedBox(height: 24),
                    const Text('Semua Diskusi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (discussions.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Belum ada diskusi. Tambahkan topik baru di atas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...discussions.map((discussion) {
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DiscussionDetailPage(
                                  discussion: discussion,
                                  userId: widget.userId,
                                  userName: widget.userName,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    discussion['title'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    discussion['message'] ?? '',
                                    style: const TextStyle(color: Colors.black87),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        discussion['userName'] ?? 'Pengguna',
                                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                      ),
                                      Text(
                                        _formatTime(discussion['createdAt']),
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
