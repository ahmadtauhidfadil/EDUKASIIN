import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'mentor_add_content_page.dart';
import 'mentor_material_page.dart';
import 'mentor_questions_page.dart';
import 'mentor_schedule_page.dart';

class MentorDashboardPage extends StatefulWidget {
  final String mentorId;
  final String mentorName;

  const MentorDashboardPage({super.key, required this.mentorId, required this.mentorName});

  @override
  State<MentorDashboardPage> createState() => _MentorDashboardPageState();
}

class _MentorDashboardPageState extends State<MentorDashboardPage> {
  int _lansiaCount = 0;
  int _kelasCount = 0;
  bool _loadingCounts = true;
  String? _countError;

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
        _kelasCount = counts['kelas'] ?? 0;
        _loadingCounts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _countError = 'Gagal memuat data dashboard';
        _loadingCounts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
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
                            'Dashboard Mentor',
                            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Kelola kelas, jawaban, dan pendampingan lansia.',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned.fill(
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.school, color: Colors.blue, size: 28),
                            ),
                          ),
                          Positioned(
                            right: -2,
                            top: -2,
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
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_loadingCounts)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 98,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 98,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _summaryItem(context, _lansiaCount.toString(), Icons.person, Colors.blue, 'Lansia'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryItem(context, _kelasCount.toString(), Icons.book, Colors.green, 'Kelas'),
                      ),
                    ],
                  ),
                if (_countError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_countError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  const Text('Aktivitas Saya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildQuickTile(context, Icons.question_answer, 'Jawab Pertanyaan', 'Lihat pertanyaan terbaru dari lansia.', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MentorQuestionsPage(mentorId: widget.mentorId)));
                  }),
                  _buildQuickTile(context, Icons.video_library, 'Materi & Kelas', 'Kelola materi dan kelas yang sedang berjalan.', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MentorMaterialPage()));
                  }),
                  _buildQuickTile(context, Icons.add_box, 'Tambah Konten', 'Tambahkan konten pembelajaran baru untuk diajukan ke admin.', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MentorAddContentPage(
                          mentorId: widget.mentorId,
                          mentorName: widget.mentorName,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: Icon(icon, color: Colors.blue)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
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
