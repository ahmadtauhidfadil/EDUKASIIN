import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:edukasin/services/firestore_service.dart';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> course;
  const DetailPage({super.key, required this.course});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool _triedRefresh = false;
  late List<Map<String, dynamic>> _modulesState;
  String _formatValue(dynamic input) {
    if (input == null) return '';
    if (input is String) return input;
    if (input is DateTime) {
      return '${input.day.toString().padLeft(2, '0')}/${input.month.toString().padLeft(2, '0')}/${input.year} ${input.hour.toString().padLeft(2, '0')}:${input.minute.toString().padLeft(2, '0')}';
    }
    if (input is Timestamp) {
      final date = input.toDate();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (input is List) {
      return input.map(_formatValue).where((s) => s.isNotEmpty).join(', ');
    }
    if (input is Map) {
      final extracted = _extractSchedule(input);
      return extracted.isNotEmpty ? extracted : input.values.map((v) => _formatValue(v)).where((s) => s.isNotEmpty).join(' ');
    }
    return input.toString();
  }

  dynamic _getFieldValue(dynamic current, List<String> keys) {
    if (current == null) return null;
    if (current is Map) {
      for (final key in keys) {
        if (current.containsKey(key)) {
          return current[key];
        }
      }

      for (final key in keys) {
        final lowerKey = key.toLowerCase();
        for (final entry in current.entries) {
          if (entry.key.toString().toLowerCase() == lowerKey) {
            return entry.value;
          }
        }
      }

      for (final entry in current.entries) {
        final entryKey = entry.key.toString().toLowerCase();
        for (final key in keys) {
          final lowerKey = key.toLowerCase();
          if (entryKey.contains(lowerKey) || lowerKey.contains(entryKey)) {
            return entry.value;
          }
        }
      }

      for (final entry in current.entries) {
        final value = _getFieldValue(entry.value, keys);
        if (value != null) return value;
      }
    } else if (current is List) {
      for (final item in current) {
        final value = _getFieldValue(item, keys);
        if (value != null) return value;
      }
    }
    return null;
  }

  dynamic _normalizeRawModules(dynamic rawModules) {
    if (rawModules is Map) {
      if (rawModules.containsKey('modules') || rawModules.containsKey('module') || rawModules.containsKey('modul')) {
        return rawModules['modules'] ?? rawModules['module'] ?? rawModules['modul'] ?? rawModules;
      }
    }
    return rawModules;
  }

  String _extractSchedule(Map<dynamic, dynamic> m) {
    return _formatValue(_getFieldValue(m, [
      'scheduleTime',
      'schedule_time',
      'schedule',
      'scheduledAt',
      'scheduled_at',
      'waktu',
      'waktu_jadwal',
      'time',
      'date',
      'tanggal',
      'jadwal',
      'datetime',
      'startTime',
      'start_time',
      'startAt',
      'start_at',
      'endTime',
      'end_time',
      'meetingTime',
      'meeting_time',
      'meetingAt',
      'meeting_at',
      'eventTime',
      'event_time',
      'tgl',
      'tgl_jadwal',
      'waktu_mulai',
      'jam_mulai',
      'jam_selesai',
    ]));
  }

  String _extractZoomLink(Map<dynamic, dynamic> m) {
    final url = _extractString(m, [
      'zoomLink',
      'zoom_link',
      'zoom',
      'zoomUrl',
      'zoom_url',
      'link',
      'joinUrl',
      'join_url',
      'join_link',
      'meetingLink',
      'meeting_link',
      'meeting_url',
      'meetUrl',
      'meet_url',
      'url',
    ], '');
    if (url.isEmpty) return 'https://app.zoom.us/wc/';
    return _normalizeUrl(url);
  }

  String _extractString(Map<dynamic, dynamic> m, List<String> keys, String fallback) {
    final value = _getFieldValue(m, keys);
    if (value == null) return fallback;
    return value.toString();
  }

  List<Map<String, dynamic>> _parseModules(dynamic rawModules) {
    rawModules = _normalizeRawModules(rawModules);
    List<dynamic> modulesList = [];

    if (rawModules is List) {
      modulesList = rawModules;
    } else if (rawModules is Map) {
      final entries = rawModules.entries.toList();
      entries.sort((a, b) {
        final aKey = int.tryParse(a.key.toString()) ?? 0;
        final bKey = int.tryParse(b.key.toString()) ?? 0;
        return aKey.compareTo(bKey);
      });
      modulesList = entries.map((e) => e.value).toList();
    } else {
      debugPrint('UNSUPPORTED MODULES TYPE: ${rawModules.runtimeType}');
    }

    return modulesList.asMap().entries.map<Map<String, dynamic>>((entry) {
      final index = entry.key;
      final module = entry.value;

      if (module is Map) {
        final scheduleValue = _getFieldValue(module, [
          'scheduleTime',
          'schedule_time',
          'schedule',
          'scheduledAt',
          'scheduled_at',
          'waktu',
          'waktu_jadwal',
          'time',
          'date',
          'tanggal',
          'jadwal',
          'datetime',
          'startTime',
          'start_time',
          'startAt',
          'start_at',
          'endTime',
          'end_time',
          'meetingTime',
          'meeting_time',
          'meetingAt',
          'meeting_at',
          'eventTime',
          'event_time',
          'tgl',
          'tgl_jadwal',
          'waktu_mulai',
          'jam_mulai',
          'jam_selesai',
        ]);

        final scheduleTime = _formatValue(scheduleValue);
        if (scheduleTime.isEmpty) {
          debugPrint('MODULE MISSING scheduleTime: ${module['name'] ?? module['title'] ?? module['modul'] ?? module}');
          debugPrint('MODULE KEYS: ${module.keys.toList()}');
          debugPrint('MODULE CANDIDATES: ${module.entries.where((entry) {
            final key = entry.key.toString().toLowerCase();
            return key.contains('time') || key.contains('date') || key.contains('jadwal') || key.contains('waktu') || key.contains('start') || key.contains('end');
          }).map((entry) => '${entry.key}: ${entry.value}').toList()}');
        }

        return {
          'number': index + 1,
          'name': _extractString(module, ['name', 'title', 'module', 'modul'], 'Modul ${index + 1}'),
          'scheduleTime': scheduleTime,
          'zoomLink': _extractZoomLink(module),
          'fileUrl': _extractString(module, ['fileUrl', 'file_url'], ''),
        };
      }

      return {
        'number': index + 1,
        'name': module?.toString() ?? 'Modul ${index + 1}',
        'scheduleTime': '',
        'zoomLink': '',
        'fileUrl': '',
      };
    }).toList();
  }

  // course-level schedule extractor removed; per-module schedules are used.

  @override
  void initState() {
    super.initState();
    final rawModules = widget.course['modules'] ?? widget.course['module'] ?? widget.course['modul'] ?? widget.course['moduls'] ?? [];
    _modulesState = _parseModules(rawModules);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRefreshModules());
  }

  Future<void> _maybeRefreshModules() async {
    if (_triedRefresh) return;
    final classId = widget.course['id']?.toString();
    debugPrint('DETAIL PAGE: maybeRefreshModules classId=$classId');
    if (classId == null || classId.isEmpty) return;
    _triedRefresh = true;
    try {
      final fresh = await FirestoreService.getClassById(classId);
      debugPrint('DETAIL PAGE: fresh class from server: $fresh');
      if (fresh != null) {
        final freshRaw = fresh['modules'] ?? fresh['module'] ?? fresh['modul'] ?? fresh['moduls'] ?? [];
        final freshModules = _parseModules(freshRaw);

        final merged = List<Map<String, dynamic>>.from(_modulesState);
        for (var i = 0; i < merged.length; i++) {
          final local = merged[i];
          if (local['scheduleTime']?.toString().isNotEmpty ?? false) continue;

          if (i < freshModules.length) {
            final candidate = freshModules[i];
            if (candidate['scheduleTime']?.toString().isNotEmpty ?? false) {
              local['scheduleTime'] = candidate['scheduleTime'];
              local['zoomLink'] = local['zoomLink']?.toString().isNotEmpty == true ? local['zoomLink'] : candidate['zoomLink'];
              local['fileUrl'] = local['fileUrl']?.toString().isNotEmpty == true ? local['fileUrl'] : candidate['fileUrl'];
              continue;
            }
          }

          final name = (local['name'] ?? '').toString().toLowerCase();
          if (name.isNotEmpty) {
            final match = freshModules.firstWhere(
              (m) => (m['name'] ?? '').toString().toLowerCase() == name,
              orElse: () => <String, dynamic>{},
            );
            if ((match['scheduleTime']?.toString().isNotEmpty ?? false)) {
              local['scheduleTime'] = match['scheduleTime'];
              local['zoomLink'] = local['zoomLink']?.toString().isNotEmpty == true ? local['zoomLink'] : match['zoomLink'];
              local['fileUrl'] = local['fileUrl']?.toString().isNotEmpty == true ? local['fileUrl'] : match['fileUrl'];
            }
          }
        }

        setState(() {
          _modulesState = merged;
        });
        debugPrint('DETAIL PAGE: merged modules from server');
      }
    } catch (e) {
      debugPrint('DETAIL PAGE: error refreshing modules: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.course['title']?.toString() ?? 'Kelas';
    final desc = widget.course['desc']?.toString() ?? widget.course['description']?.toString() ?? '';
    // course-level schedule removed; focus on per-module schedules
    final rawModules = widget.course['modules'] ?? widget.course['module'] ?? widget.course['modul'] ?? widget.course['moduls'] ?? [];
    final modules = _modulesState;
    debugPrint('DETAIL PAGE RAW MODULES (passed): $rawModules');
    debugPrint('DETAIL PAGE MODULES STATE LENGTH: ${_modulesState.length}');
    debugPrint('DETAIL PAGE MODULES STATE: ${_modulesState.map((m) => {'name': m['name'], 'scheduleTime': m['scheduleTime']}).toList()}');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Detail Kelas'),
        backgroundColor: Colors.blue.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (desc.isNotEmpty)
              Text(desc, style: const TextStyle(fontSize: 14, color: Colors.black87)),
            // Note: course-level schedule intentionally removed. Per-module schedules shown below.
            const SizedBox(height: 24),

            // Modul Pembelajaran header
            const Text('Modul Pembelajaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            if (modules.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: const Text('Belum ada modul untuk kelas ini.'),
              )
            else
              ...modules.map((module) => _buildModuleCard(module)),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kembali ke Beranda', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _normalizeUrl(String value) {
    final trimmed = value.toString().trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('www.')) {
      return 'https://$trimmed';
    }
    if (trimmed.contains('zoom.us') || trimmed.contains('zoom.com')) {
      return 'https://$trimmed';
    }
    return trimmed;
  }

  void _showZoomSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openZoomLink(BuildContext context, String url) async {
    const target = 'https://app.zoom.us/wc/';
    final uri = Uri.tryParse(target);
    if (uri == null) {
      _showZoomSnackBar('Link Zoom tidak valid');
      return;
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!launched) {
        _showZoomSnackBar('Tidak dapat membuka link Zoom');
      }
    } catch (e) {
      if (!mounted) return;
      _showZoomSnackBar('Gagal membuka link Zoom');
    }
  }

  Widget _buildModuleCard(Map<String, dynamic> module) {
    final number = module['number'] ?? 0;
    final name = module['name']?.toString() ?? 'Modul';
    final scheduleTime = module['scheduleTime']?.toString() ?? '';
    final zoomLink = module['zoomLink']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nomor dan nama modul
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      number.toString(),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Jadwal
            if (scheduleTime.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        scheduleTime,
                        style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openZoomLink(context, zoomLink),
                icon: const Icon(Icons.video_camera_front, size: 18),
                label: const Text('Zoom'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}