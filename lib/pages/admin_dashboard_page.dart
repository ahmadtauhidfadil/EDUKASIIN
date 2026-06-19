import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'admin_content_page.dart';
import 'admin_forum_monitoring_page.dart';
import 'admin_schedule_page.dart';
import 'admin_users_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoadingCounts = true;
  int _lansiaCount = 0;
  int _mentorCount = 0;
  int _kelasCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardCounts();
  }

  Future<void> _loadDashboardCounts() async {
    try {
      final counts = await FirestoreService.getDashboardCounts();
      if (!mounted) return;
      setState(() {
        _lansiaCount = counts['lansia'] ?? 0;
        _mentorCount = counts['mentor'] ?? 0;
        _kelasCount = counts['kelas'] ?? 0;
        _isLoadingCounts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingCounts = false;
      });
    }
  }

  String _countLabel(int value) {
    return _isLoadingCounts ? '...' : value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[100],
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade900, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Dashboard Admin',
                              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Pantau data lansia dan mentor dengan cepat.',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Stack(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.admin_panel_settings, color: Colors.blue, size: 28),
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
                  Row(
                    children: [
                      Expanded(
                        child: _summaryItem(context, _countLabel(_lansiaCount), Icons.group, Colors.blue, 'Lansia'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryItem(context, _countLabel(_mentorCount), Icons.school, Colors.green, 'Mentor'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryItem(context, _countLabel(_kelasCount), Icons.book, Colors.orange, 'Kelas'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Menu Cepat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ..._quickActions(context).map((action) => _buildActionTile(context, action.icon, action.title, action.subtitle, action.onTap)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_AdminAction> _quickActions(BuildContext context) {
    return [
      _AdminAction(
        icon: Icons.group,
        title: 'Kelola Pengguna',
        subtitle: 'Tambah, edit, atau hapus akun lansia dan mentor.',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersPage())),
      ),
      _AdminAction(
        icon: Icons.video_library,
        title: 'Validasi Konten',
        subtitle: 'Atur kelas, materi, dan video tutorial.',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminContentPage())),
      ),
      _AdminAction(
        icon: Icons.forum,
        title: 'Pantau Forum',
        subtitle: 'Lihat topik diskusi dan moderasi komentar.',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminForumMonitoringPage())),
      ),
    ];
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: Colors.blue.shade50, child: Icon(icon, color: Colors.blue)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18),
            ],
          ),
        ),
      ),
    );
  }


  Widget _summaryItem(BuildContext context, String title, IconData icon, Color color, String label) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(label), duration: const Duration(seconds: 2)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _AdminAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _AdminAction({required this.icon, required this.title, required this.subtitle, required this.onTap});
}
