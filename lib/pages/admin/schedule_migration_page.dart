import 'package:flutter/material.dart';
import '../../utils/schedule_migration_util.dart';

/// Admin page for managing schedule migration
class ScheduleMigrationPage extends StatefulWidget {
  const ScheduleMigrationPage({super.key});

  @override
  State<ScheduleMigrationPage> createState() => _ScheduleMigrationPageState();
}

class _ScheduleMigrationPageState extends State<ScheduleMigrationPage> {
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Migrasi Schedule'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Migrasi Schedule Database',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pindahkan scheduleTime dari struktur modules ke koleksi schedules yang baru.',
                    style: TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⚠️ PENTING: Buat backup database sebelum menjalankan migrasi!',
                      style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info Section
            const Text('ℹ️ Informasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '📍 Struktur Lama:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '/kelas/{id}/modules[]/scheduleTime',
                    style: TextStyle(fontFamily: 'monospace', color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '📍 Struktur Baru:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '/schedules/{id} dengan classId, moduleIndex, scheduleTime',
                    style: TextStyle(fontFamily: 'monospace', color: Colors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Steps Section
            const Text('🔧 Langkah-Langkah', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildStepCard(
              number: '1',
              title: 'Verifikasi Data',
              description: 'Cek status sebelum migrasi untuk mengetahui berapa banyak data yang perlu dimigrasikan.',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildStepCard(
              number: '2',
              title: 'Migrasi Lengkap',
              description:
                  'Pindahkan semua scheduleTime ke koleksi baru, bersihkan data lama, dan verifikasi hasil. (Rekomendasi)',
              color: Colors.green,
              isRecommended: true,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            const Text('⚡ Aksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Verify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _handleVerify,
                icon: const Icon(Icons.info),
                label: const Text('1. Verifikasi Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Full Migration Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _handleFullMigration,
                icon: const Icon(Icons.upload_file),
                label: const Text('2. Migrasi Lengkap (Recommended)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Divider
            Divider(
              color: Colors.grey.shade300,
              thickness: 1,
              height: 32,
            ),

            const Text(
              '⚙️ Advanced Options',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // Migrate Only Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isRunning ? null : _handleMigrateOnly,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Hanya Migrasi (tanpa cleanup)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cleanup Only Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isRunning ? null : _handleCleanupOnly,
                icon: const Icon(Icons.cleaning_services),
                label: const Text('Hanya Cleanup (hapus data lama)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Re-verify Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isRunning ? null : _handleVerify,
                icon: const Icon(Icons.check_circle),
                label: const Text('Verifikasi Ulang'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '✅ Keuntungan Struktur Baru:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Data lebih terstruktur dan terpisah'),
                  Text('• Mudah menambah multiple schedules per modul'),
                  Text('• Query lebih efisien'),
                  Text('• Update schedule tidak perlu update seluruh kelas'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String number,
    required String title,
    required String description,
    required Color color,
    bool isRecommended = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (isRecommended)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Recommended',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(color: Colors.black87, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVerify() async {
    setState(() => _isRunning = true);
    await ScheduleMigrationUtil.verifyAndShow(context: context);
    setState(() => _isRunning = false);
  }

  Future<void> _handleFullMigration() async {
    final confirmed = await _showConfirmDialog(
      title: 'Konfirmasi Migrasi Lengkap',
      message: 'Ini akan:\n'
          '1. Memindahkan semua scheduleTime ke koleksi schedules\n'
          '2. Menghapus scheduleTime dari modules\n'
          '3. Memverifikasi hasil\n\n'
          'Pastikan sudah ada backup database!',
    );

    if (!confirmed) return;

    setState(() => _isRunning = true);
    if (mounted) {
      final success = await ScheduleMigrationUtil.runCompleteMigration(context: context);
      if (mounted) {
        setState(() => _isRunning = false);
      }
    }
  }

  Future<void> _handleMigrateOnly() async {
    final confirmed = await _showConfirmDialog(
      title: 'Konfirmasi Migrasi',
      message: 'Ini akan memindahkan scheduleTime ke koleksi schedules\n'
          'tetapi TIDAK menghapus data lama di modules.',
    );

    if (!confirmed) return;

    setState(() => _isRunning = true);
    if (mounted) {
      await ScheduleMigrationUtil.migrateOnly(context: context);
      if (mounted) {
        setState(() => _isRunning = false);
      }
    }
  }

  Future<void> _handleCleanupOnly() async {
    final confirmed = await _showConfirmDialog(
      title: 'Konfirmasi Cleanup',
      message: 'Ini akan menghapus semua scheduleTime dari modules.\n\n'
          '⚠️ Pastikan semua schedule sudah ada di koleksi schedules!',
    );

    if (!confirmed) return;

    setState(() => _isRunning = true);
    if (mounted) {
      await ScheduleMigrationUtil.cleanupOnly(context: context);
      if (mounted) {
        setState(() => _isRunning = false);
      }
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
