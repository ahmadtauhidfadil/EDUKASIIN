import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

/// Utility class for managing schedule migration from modules to schedules collection
class ScheduleMigrationUtil {
  /// Run complete migration workflow:
  /// 1. Verify current state
  /// 2. Migrate scheduleTime from modules to schedules collection
  /// 3. Remove scheduleTime from modules
  /// 4. Verify migration success
  static Future<bool> runCompleteMigration({
    required BuildContext context,
    VoidCallback? onProgress,
  }) async {
    try {
      // Step 1: Verify before migration
      _showMigrationDialog(
        context,
        title: 'Migration Dimulai',
        message: 'Verifikasi data sebelum migrasi...',
      );

      final verifyBefore = await FirestoreService.verifyMigration();
      print('❌ Before Migration: ${verifyBefore['orphanedSchedules']} orphaned schedules found');

      // Step 2: Migrate scheduleTime
      _showMigrationDialog(
        context,
        title: 'Migrasi Data',
        message: 'Memindahkan scheduleTime ke koleksi schedules...\n\n'
            'Total kelas: ${verifyBefore['totalClasses']}\n'
            'Kelas dengan jadwal: ${verifyBefore['classesWithOrphanedSchedules']}',
      );

      onProgress?.call();
      final migrationResult = await FirestoreService.migrateScheduleTimesToSchedulesCollection();

      print('✅ Migration Result:');
      print('   - Schedules Created: ${migrationResult['schedulesCreated']}');
      print('   - Schedules Skipped: ${migrationResult['schedulesSkipped']}');
      print('   - Errors: ${migrationResult['errors']}');

      if ((migrationResult['errors'] as int) > 0) {
        print('❌ Error messages:');
        for (final msg in migrationResult['errorMessages'] as List) {
          print('   - $msg');
        }
      }

      // Step 3: Remove scheduleTime from modules
      _showMigrationDialog(
        context,
        title: 'Pembersihan Data Lama',
        message: 'Menghapus scheduleTime dari struktur modules...\n\n'
            'Schedules berhasil dibuat: ${migrationResult['schedulesCreated']}',
      );

      onProgress?.call();
      final cleanupResult = await FirestoreService.removeScheduleTimeFromModules();

      print('✅ Cleanup Result:');
      print('   - Classes Updated: ${cleanupResult['classesUpdated']}');
      print('   - Modules Updated: ${cleanupResult['modulesUpdated']}');
      print('   - Errors: ${cleanupResult['errors']}');

      // Step 4: Verify after migration
      _showMigrationDialog(
        context,
        title: 'Verifikasi Akhir',
        message: 'Memverifikasi hasil migrasi...\n\n'
            'Kelas diupdate: ${cleanupResult['classesUpdated']}',
      );

      onProgress?.call();
      final verifyAfter = await FirestoreService.verifyMigration();

      print('✅ After Migration: ${verifyAfter['orphanedSchedules']} orphaned schedules remaining');

      // Success if no errors and no orphaned schedules
      if ((migrationResult['errors'] as int) == 0 &&
          (cleanupResult['errors'] as int) == 0 &&
          (verifyAfter['orphanedSchedules'] as int) == 0) {
        _showSuccessDialog(
          context,
          title: '✅ Migrasi Berhasil!',
          message: 'Schedules berhasil dipindahkan:\n\n'
              '📊 Statistik:\n'
              '• Schedules Dibuat: ${migrationResult['schedulesCreated']}\n'
              '• Kelas Diupdate: ${cleanupResult['classesUpdated']}\n'
              '• Modules Dibersihkan: ${cleanupResult['modulesUpdated']}\n\n'
              'Data lama sudah dihapus dan tidak ada lagi scheduleTime di modules.',
        );
        return true;
      } else {
        _showErrorDialog(
          context,
          title: '⚠️ Migrasi Selesai dengan Peringatan',
          message: 'Migrasi selesai tetapi ada beberapa masalah:\n\n'
              '❌ Errors saat migrasi: ${migrationResult['errors']}\n'
              '❌ Errors saat cleanup: ${cleanupResult['errors']}\n'
              '❌ Orphaned schedules tersisa: ${verifyAfter['orphanedSchedules']}\n\n'
              'Silahkan periksa console untuk detail error.',
        );
        return false;
      }
    } catch (e) {
      print('❌ Migration error: $e');
      _showErrorDialog(
        context,
        title: '❌ Migrasi Gagal',
        message: 'Terjadi error saat migrasi:\n\n$e',
      );
      return false;
    }
  }

  /// Just migrate scheduleTime to schedules collection (without cleanup)
  static Future<bool> migrateOnly({required BuildContext context}) async {
    try {
      _showMigrationDialog(
        context,
        title: 'Migrasi Data',
        message: 'Memindahkan scheduleTime ke koleksi schedules...',
      );

      final result = await FirestoreService.migrateScheduleTimesToSchedulesCollection();

      if ((result['errors'] as int) == 0) {
        _showSuccessDialog(
          context,
          title: '✅ Migrasi Berhasil!',
          message: 'Schedules berhasil dibuat:\n\n'
              '${result['schedulesCreated']} schedules dibuat\n'
              '${result['schedulesSkipped']} schedules sudah ada',
        );
        return true;
      } else {
        _showErrorDialog(
          context,
          title: '⚠️ Migrasi dengan Error',
          message: '${result['schedulesCreated']} schedules berhasil dibuat\n'
              'Tetapi ada ${result['errors']} error',
        );
        return false;
      }
    } catch (e) {
      _showErrorDialog(
        context,
        title: '❌ Migrasi Gagal',
        message: 'Error: $e',
      );
      return false;
    }
  }

  /// Cleanup only: remove scheduleTime from modules
  static Future<bool> cleanupOnly({required BuildContext context}) async {
    try {
      _showMigrationDialog(
        context,
        title: 'Pembersihan Data',
        message: 'Menghapus scheduleTime dari struktur modules...',
      );

      final result = await FirestoreService.removeScheduleTimeFromModules();

      if ((result['errors'] as int) == 0) {
        _showSuccessDialog(
          context,
          title: '✅ Pembersihan Berhasil!',
          message: '${result['classesUpdated']} kelas diupdate\n'
              '${result['modulesUpdated']} modules dibersihkan',
        );
        return true;
      } else {
        _showErrorDialog(
          context,
          title: '⚠️ Pembersihan dengan Error',
          message: '${result['classesUpdated']} kelas diupdate\n'
              'Tetapi ada ${result['errors']} error',
        );
        return false;
      }
    } catch (e) {
      _showErrorDialog(
        context,
        title: '❌ Pembersihan Gagal',
        message: 'Error: $e',
      );
      return false;
    }
  }

  /// Verify current state before migration
  static Future<void> verifyAndShow({required BuildContext context}) async {
    try {
      _showMigrationDialog(
        context,
        title: 'Verifikasi',
        message: 'Memverifikasi data...',
      );

      final result = await FirestoreService.verifyMigration();

      String details = '📊 Total Kelas: ${result['totalClasses']}\n'
          '❌ Kelas dengan Jadwal Lama: ${result['classesWithOrphanedSchedules']}\n'
          '❌ Total Jadwal Lama: ${result['orphanedSchedules']}\n\n';

      if ((result['orphanedDetails'] as List).isEmpty) {
        details += '✅ Tidak ada jadwal yang perlu dimigrasikan';
      } else {
        details += '📋 Detail Jadwal yang Perlu Dimigrasikan:\n';
        for (final detail in result['orphanedDetails'] as List) {
          final d = detail as Map<String, dynamic>;
          details +=
              '• ${d['className']} - Modul ${d['moduleIndex']}: ${d['scheduleTime']}\n';
        }
      }

      Navigator.of(context).pop(); // Close dialog
      _showInfoDialog(
        context,
        title: 'Hasil Verifikasi',
        message: details,
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close dialog
      _showErrorDialog(
        context,
        title: '❌ Verifikasi Gagal',
        message: 'Error: $e',
      );
    }
  }

  // ========== Dialog Helpers ==========

  static void _showMigrationDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  static void _showSuccessDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    Navigator.of(context).pop(); // Close loading dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    Navigator.of(context).pop(); // Close loading dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
