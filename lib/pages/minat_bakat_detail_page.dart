import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/cloudinary_service.dart';
import '../services/firestore_service.dart';

class MinatBakatDetailPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const MinatBakatDetailPage({super.key, required this.item});

  @override
  State<MinatBakatDetailPage> createState() => _MinatBakatDetailPageState();
}

class _MinatBakatDetailPageState extends State<MinatBakatDetailPage> {
  late Map<String, dynamic> _item;
  late String _title;
  late String _description;
  late String _photoUrl;
  String? _videoUrl;
  late List<Map<String, dynamic>> _modules;
  bool _isLoading = false;
  bool _isClassCreated = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _item = Map<String, dynamic>.from(widget.item);
    _title = _item['title']?.toString() ?? 'Minat & Bakat';
    _description = _item['description']?.toString() ?? 'Tidak ada deskripsi';
    _photoUrl = _item['photoUrl']?.toString() ?? '';
    _videoUrl = _item['videoUrl']?.toString();
    final rawModules = _item['modules'];
    if (rawModules is List) {
      _modules = rawModules.map<Map<String, dynamic>>((module) {
        if (module is String) {
          return {
            'name': module,
            'fileUrl': '',
          };
        }
        return {
          'name': module['name']?.toString() ?? 'Modul',
          'fileUrl': module['fileUrl']?.toString() ?? '',
        };
      }).toList();
    } else {
      _modules = List.generate(5, (index) => {
            'name': 'Modul ${index + 1}',
            'fileUrl': '',
          });
    }
  }

  Future<void> _updateFirestore() async {
    await FirestoreService.updateMinatBakat(_item['id'].toString(), {
      'title': _title,
      'description': _description,
      'photoUrl': _photoUrl,
      'videoUrl': _videoUrl ?? '',
      'modules': _modules,
      'updatedAt': DateTime.now(),
    });
  }

  Future<void> _pickIntroVideo() async {
    final typeGroup = XTypeGroup(
      label: 'video',
      mimeTypes: ['video/*'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    final selectedFile = File(file.path);
    setState(() {
      _isLoading = true;
    });
    final uploadedUrl = await CloudinaryService.uploadFile(selectedFile);
    if (uploadedUrl != null) {
      setState(() {
        _videoUrl = uploadedUrl;
      });
      await _updateFirestore();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video pengenalan berhasil diunggah.')));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengunggah video.')));
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickModuleFile(int index) async {
    final typeGroup = XTypeGroup(
      label: 'files',
      mimeTypes: ['*/*'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    final selectedFile = File(file.path);
    setState(() {
      _isLoading = true;
    });
    final uploadedUrl = await CloudinaryService.uploadFile(selectedFile);
    if (uploadedUrl != null) {
      setState(() {
        _modules[index]['fileUrl'] = uploadedUrl;
      });
      await _updateFirestore();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File modul berhasil diunggah.')));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengunggah file modul.')));
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _editModuleName(int index) async {
    final controller = TextEditingController(text: _modules[index]['name'] ?? '');
    final updated = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Nama Modul'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nama Modul'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Simpan')),
        ],
      ),
    );
    if (updated == null || updated.isEmpty) return;
    setState(() {
      _modules[index]['name'] = updated;
    });
    await _updateFirestore();
  }

  Future<void> _deleteModule(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Modul'),
        content: const Text('Yakin ingin menghapus modul ini beserta file terkait?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _modules[index] = {'name': '', 'fileUrl': ''};
    });
    await _updateFirestore();
  }

  Future<void> _createClass() async {
    setState(() {
      _isLoading = true;
    });
    final mentorId = FirebaseAuth.instance.currentUser?.uid ?? 'mentor';
    await FirestoreService.createClass({
      'title': _title,
      'description': _description,
      'photoUrl': _photoUrl,
      'videoUrl': _videoUrl ?? '',
      'modules': _modules,
      'mentorId': mentorId,
      'createdAt': DateTime.now(),
      'status': 'published',
    });
    setState(() {
      _isClassCreated = true;
      _isLoading = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Materi terdaftar sebagai kelas.')));
  }

  void _showModuleActions(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Tambah / Ganti File Modul'),
                onTap: () {
                  Navigator.pop(context);
                  _pickModuleFile(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Nama Modul'),
                onTap: () {
                  Navigator.pop(context);
                  _editModuleName(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Hapus Modul', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteModule(index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('Edukasin', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey.shade200,
                    child: _photoUrl.isNotEmpty
                        ? Image.network(_photoUrl, fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image, size: 50, color: Colors.grey),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(_title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_description, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6)),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.play_circle_outline, color: Colors.blue.shade600, size: 24),
                          const SizedBox(width: 12),
                          const Text('Video Pengenalan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          height: 150,
                          color: Colors.grey.shade300,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _videoUrl != null && _videoUrl!.isNotEmpty
                                  ? Image.network(_videoUrl!, fit: BoxFit.cover)
                                  : Container(color: Colors.grey.shade300),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.shade600.withOpacity(0.7),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _pickIntroVideo,
                        icon: const Icon(Icons.upload_file),
                        label: Text(_videoUrl != null && _videoUrl!.isNotEmpty ? 'Ganti Video' : 'Upload Video'),
                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.list_alt_outlined, color: Colors.blue.shade600, size: 24),
                          const SizedBox(width: 12),
                          const Text('Modul Pembelajaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_modules.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Belum ada modul. Tambahkan modul baru.'),
                        ),
                      ...List.generate(
                        _modules.length,
                        (index) {
                          final module = _modules[index];
                          final name = module['name']?.toString() ?? 'Modul ${index + 1}';
                          final fileUrl = module['fileUrl']?.toString() ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () => _showModuleActions(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                          if (fileUrl.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text('File tersedia', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.more_vert, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                setState(() {
                                  _modules.add({'name': 'Modul Baru', 'fileUrl': ''});
                                });
                                await _updateFirestore();
                              },
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Modul'),
                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading || _isClassCreated ? null : _createClass,
                  child: Text(_isClassCreated ? 'Sudah Terdaftar sebagai Kelas' : 'Daftarkan sebagai Kelas'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.2),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
