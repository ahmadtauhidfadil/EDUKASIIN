import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class AdminForumMonitoringPage extends StatefulWidget {
  const AdminForumMonitoringPage({super.key});

  @override
  State<AdminForumMonitoringPage> createState() => _AdminForumMonitoringPageState();
}

class _AdminForumMonitoringPageState extends State<AdminForumMonitoringPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _posts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInappropriatePosts();
  }

  Future<void> _loadInappropriatePosts() async {
    setState(() {
      _isLoading = true;
      _posts = [];
      _error = null;
    });
    try {
      final items = await FirestoreService.getInappropriatePosts();
      setState(() {
        _posts = items;
      });
    } catch (e, st) {
      setState(() {
        _posts = [];
        _error = e.toString();
      });
      print('Error loading inappropriate posts: $e');
      print(st);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePost(String collectionName, String postId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Takedown Post'),
        content: Text('Apakah Anda yakin ingin menghapus post "$title"?\n\nTindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirestoreService.deleteForumPost(collectionName, postId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post berhasil dihapus')));
        await _loadInappropriatePosts();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus post: $e')));
      }
    }
  }

  Future<void> _approvePost(String collectionName, String postId) async {
    try {
      await FirestoreService.approveFlaggedPost(collectionName, postId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post di-unflag (diterima)')));
      await _loadInappropriatePosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal unflag post: $e')));
    }
  }

  Widget _buildForumPostCard(Map<String, dynamic> post) {
    final title = post['title']?.toString() ?? 'Forum Post';
    final content = post['content']?.toString() ?? '';
    final authorName = post['authorName']?.toString() ?? 'Anonymous';
    final flagReason = post['flagReason']?.toString() ?? 'Konten kurang pantas';
    final collectionName = post['collectionName']?.toString() ?? '';
    final postId = post['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan title dan flag badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flag, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        const Text(
                          'Flagged',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Content preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Flag reason
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.red.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Alasan: $flagReason',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Author & metadata
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Oleh: $authorName',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deletePost(collectionName, postId, title),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Takedown'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _approvePost(collectionName, postId),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Unflag'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade600, Colors.blue.shade900],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pantau Forum',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Review dan takedown forum yang kurang pantas',
                          style: TextStyle(fontSize: 14, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Forum Flagged', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                    if (!_isLoading && _error == null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _loadInappropriatePosts,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.refresh, color: Colors.blue.shade600, size: 20),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.blue.shade600),
                      const SizedBox(height: 16),
                      const Text('Memuat forum yang flagged...', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                )
              else if (_posts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.verified, color: Colors.green.shade600, size: 30),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Semua Forum Bersih',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tidak ada forum yang flagged sebagai kurang pantas saat ini',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Error: $_error',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadInappropriatePosts,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Muat Ulang', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: RefreshIndicator(
                    onRefresh: _loadInappropriatePosts,
                    color: Colors.blue.shade600,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _posts.length,
                      itemBuilder: (context, i) => _buildForumPostCard(_posts[i]),
                    ),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}
