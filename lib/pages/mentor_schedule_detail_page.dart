import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class MentorScheduleDetailPage extends StatefulWidget {
  final Map<String, dynamic> classData;

  const MentorScheduleDetailPage({super.key, required this.classData});

  @override
  State<MentorScheduleDetailPage> createState() => _MentorScheduleDetailPageState();
}

class _MentorScheduleDetailPageState extends State<MentorScheduleDetailPage> {
  late Map<String, dynamic> _classData;
  late List<Map<String, dynamic>> _modules;
  Map<int, Map<String, dynamic>> _schedules = {}; // Schedules loaded from database
  bool _isSaving = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _classData = Map<String, dynamic>.from(widget.classData);
    _modules = _parseModules(_classData['modules']);
    _loadSchedules();
  }

  /// Load schedules from Firestore
  Future<void> _loadSchedules() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      _schedules = await FirestoreService.getSchedulesByClassId(_classData['id'].toString());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat jadwal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _parseModules(dynamic rawModules) {
    if (rawModules is List) {
      return rawModules.map<Map<String, dynamic>>((module) {
        if (module is Map<String, dynamic>) {
          return {
            'name': module['name']?.toString() ?? 'Modul',
            'fileUrl': module['fileUrl']?.toString() ?? module['file_url']?.toString() ?? '',
            'scheduleTime': module['scheduleTime']?.toString() ?? module['waktu']?.toString() ?? module['time']?.toString() ?? '',
          };
        }
        if (module is Map) {
          return {
            'name': module['name']?.toString() ?? 'Modul',
            'fileUrl': module['fileUrl']?.toString() ?? module['file_url']?.toString() ?? '',
            'scheduleTime': module['scheduleTime']?.toString() ?? module['waktu']?.toString() ?? module['time']?.toString() ?? '',
          };
        }

        return {
          'name': module?.toString() ?? 'Modul',
          'fileUrl': '',
          'scheduleTime': '',
        };
      }).toList();
    }

    return [];
  }

  Future<void> _editSchedule(int index) async {
    if (!mounted) return;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    if (!mounted) return;

    final scheduled = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final formattedSchedule = _formatDateTime(scheduled);

    // Update local state immediately for UI feedback
    setState(() {
      _schedules[index] = {
        'scheduleTime': formattedSchedule,
        'moduleIndex': index,
        'moduleName': _modules[index]['name'] ?? 'Modul',
      };
    });

    // Save to Firestore
    await _saveScheduleToFirestore(index, formattedSchedule);
  }

  Future<void> _removeSchedule(int index) async {
    setState(() {
      _schedules.remove(index);
    });
    await _deleteScheduleFromFirestore(index);
  }

  String _formatDateTime(DateTime dateTime) {
    const weekdays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final day = weekdays[dateTime.weekday - 1];
    final dayNum = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day, $dayNum/$month/$year • $hour:$minute';
  }

  /// Save schedule to Firestore in the schedules collection
  Future<void> _saveScheduleToFirestore(int moduleIndex, String scheduleTime) async {
    if (!mounted) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final moduleName = _modules[moduleIndex]['name']?.toString() ?? 'Modul';
      await FirestoreService.saveSchedule(
        _classData['id'].toString(),
        moduleIndex,
        moduleName,
        scheduleTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal modul berhasil disimpan.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan jadwal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Delete schedule from Firestore
  Future<void> _deleteScheduleFromFirestore(int moduleIndex) async {
    if (!mounted) return;
    setState(() {
      _isSaving = true;
    });

    try {
      await FirestoreService.deleteSchedule(
        _classData['id'].toString(),
        moduleIndex,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal modul berhasil dihapus.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus jadwal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _classData['title']?.toString() ?? 'Kelas';

    return Scaffold(
      appBar: AppBar(
        title: Text('Jadwal Kelas: $title'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (_classData['description']?.toString().isNotEmpty ?? false)
                  Text(_classData['description'].toString(), style: const TextStyle(color: Colors.black87)),
                const SizedBox(height: 20),
                const Text('Modul dan Jadwal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (_modules.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('Tidak ada modul tersedia. Tambahkan modul terlebih dahulu di halaman Materi & Kelas.'),
                  )
                else
                  ...List.generate(_modules.length, (index) {
                    final module = _modules[index];
                    final schedule = _schedules[index];
                    final scheduleTime = schedule?['scheduleTime']?.toString() ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(module['name']?.toString() ?? 'Modul', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (scheduleTime.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 16, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(scheduleTime, style: const TextStyle(color: Colors.black54))),
                                ],
                              )
                            else
                              const Text('Belum ditentukan jadwal', style: TextStyle(color: Colors.black54)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _editSchedule(index),
                                    child: Text(scheduleTime.isEmpty ? 'Tambah Jadwal' : 'Edit Jadwal'),
                                  ),
                                ),
                                if (scheduleTime.isNotEmpty) ...[
                                  const SizedBox(width: 12),
                                  OutlinedButton(
                                    onPressed: () => _removeSchedule(index),
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 80),
              ],
            ),
          if (_isSaving)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
