import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'mentor_schedule_detail_page.dart';

class MentorSchedulePage extends StatefulWidget {
  const MentorSchedulePage({super.key});

  @override
  State<MentorSchedulePage> createState() => _MentorSchedulePageState();
}

class _MentorSchedulePageState extends State<MentorSchedulePage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Tidak dapat memuat data. Silakan masuk kembali.';
      });
      return;
    }

    try {
      final classes = await FirestoreService.getClassesForMentor(user.uid);
      if (mounted) {
        setState(() {
          _classes = classes;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat jadwal. Coba lagi nanti.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          const Text('Jadwal Kelas Saya', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Atur jadwal kelas dan tambahkan jadwal per modul untuk lansia.', style: TextStyle(fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 24),
          if (_isLoading) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 24),
          ] else if (_error != null) ...[
            _buildErrorState(_error!, _loadClasses),
          ] else if (_classes.isEmpty) ...[
            _buildEmptyState(),
          ] else ..._classes.map((item) => _buildClassCard(item)),
        ],
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> item) {
    final title = item['title']?.toString() ?? 'Kelas';
    final modulesRaw = item['modules'];
    final modules = <Map<String, dynamic>>[];
    if (modulesRaw is List) {
      for (final module in modulesRaw) {
        if (module is Map<String, dynamic>) {
          modules.add(module);
        } else if (module is Map) {
          modules.add(Map<String, dynamic>.from(module));
        } else {
          modules.add({'name': module?.toString() ?? 'Modul', 'fileUrl': ''});
        }
      }
    }

    final scheduledCount = modules.where((module) => module['scheduleTime']?.toString().isNotEmpty ?? false).length;
    final moduleCount = modules.length;
    final subtitle = moduleCount > 0
        ? '$moduleCount modul • $scheduledCount terjadwal'
        : 'Belum ada modul. Tambahkan modul di Materi & Kelas.';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(subtitle, style: const TextStyle(color: Colors.black54)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MentorScheduleDetailPage(classData: item)),
          );
          _loadClasses();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Belum ada kelas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
          const SizedBox(height: 8),
          const Text('Anda belum menambahkan kelas. Buat kelas baru melalui Materi & Kelas, lalu atur jadwal setiap modul di sini.'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buka Materi & Kelas untuk membuat kelas baru.')));
            },
            child: const Text('Buka Materi & Kelas'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Terjadi kesalahan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.red.shade900)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
