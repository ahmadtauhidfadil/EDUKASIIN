// ignore_for_file: unused_element

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
// crypto removed (using unsigned preset)

class AdminMinatBakatPage extends StatefulWidget {
  const AdminMinatBakatPage({super.key});

  @override
  State<AdminMinatBakatPage> createState() => _AdminMinatBakatPageState();
}

class _AdminMinatBakatPageState extends State<AdminMinatBakatPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String? _error;
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await FirestoreService.getMinatBakatItems(query: _query);
      if (!mounted) return;
      setState(() {
        _items.clear();
        _items.addAll(items);
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal mengambil data minat bakat.';
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

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _query = value;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _loadItems();
    });
  }

  Future<void> _openEditor({Map<String, dynamic>? item}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MinatBakatFormPage(item: item)),
    );
    if (changed == true) {
      _loadItems();
    }
  }

  // Cloudinary unsigned upload preset (user provided)
  static const String _cloudName = 'dgbczkxwg';
  static const String _uploadPreset = 'flutter_upload';

  Future<String?> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (picked == null) return null;

      final file = File(picked.path);
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return body['secure_url'] as String?;
      } else {
        print('Cloudinary upload failed: ${res.statusCode} ${res.body}');
        return null;
      }
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Minat Bakat'),
        content: Text('Hapus "${item['title']}" dari daftar minat bakat?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirestoreService.deleteMinatBakat(item['id'].toString());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minat bakat berhasil dihapus'), backgroundColor: Colors.green));
        _loadItems();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus minat bakat'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Minat Bakat'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _items.isEmpty
                        ? const Center(child: Text('Tidak ada minat bakat. Tambahkan minat bakat baru.'))
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: GridView.builder(
                              padding: const EdgeInsets.only(bottom: 120),
                              physics: const BouncingScrollPhysics(),
                              itemCount: _items.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                mainAxisExtent: 270,
                              ),
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return _MinatBakatCard(
                                  item: item,
                                  onEdit: () => _openEditor(item: item),
                                  onDelete: () => _confirmDelete(item),
                                );
                              },
                            ),
                          ),
          ),
          const SizedBox(height: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        label: const Text('Tambah Minat Bakat'),
        icon: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _MinatBakatCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MinatBakatCard({required this.item, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final photoUrl = item['photoUrl']?.toString() ?? '';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: Container(
              height: 110,
              color: Colors.blueGrey.shade50,
              child: photoUrl.isNotEmpty
                  ? Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.image, size: 48, color: Colors.blueGrey)))
                  : const Center(child: Icon(Icons.image, size: 48, color: Colors.blueGrey)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      item['description'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onEdit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Edit', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDelete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Hapus', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MinatBakatFormPage extends StatefulWidget {
  final Map<String, dynamic>? item;

  const MinatBakatFormPage({super.key, this.item});

  @override
  State<MinatBakatFormPage> createState() => _MinatBakatFormPageState();
}

class _MinatBakatFormPageState extends State<MinatBakatFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _photoUrlController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.item?['title'] ?? '';
    _descriptionController.text = widget.item?['description'] ?? '';
    _photoUrlController.text = widget.item?['photoUrl'] ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  // Cloudinary unsigned upload preset (user provided)
  static const String _cloudName = 'dgbczkxwg';
  static const String _uploadPreset = 'flutter_upload';

  Future<String?> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (picked == null) return null;

      final file = File(picked.path);
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return body['secure_url'] as String?;
      } else {
        print('Cloudinary upload failed: ${res.statusCode} ${res.body}');
        return null;
      }
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
    });

    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'photoUrl': _photoUrlController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (widget.item == null) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    try {
      if (widget.item == null) {
        await FirestoreService.createMinatBakat(data);
      } else {
        await FirestoreService.updateMinatBakat(widget.item!['id'].toString(), data);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.item == null ? 'Minat bakat berhasil ditambahkan' : 'Minat bakat berhasil diperbarui')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan data'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Tambah Minat Bakat' : 'Edit Minat Bakat'),
        backgroundColor: Colors.blue.shade700,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18)))),
                    validator: (value) => (value?.trim().isEmpty ?? true) ? 'Nama minat bakat harus diisi' : null,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade300)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _photoUrlController.text.trim().isEmpty
                          ? const Center(child: Text('GAMBAR', style: TextStyle(color: Colors.black45, fontSize: 18, fontWeight: FontWeight.bold)))
                          : Image.network(
                              _photoUrlController.text.trim(),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Center(child: Text('Gagal memuat gambar', style: TextStyle(color: Colors.red))),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Memilih gambar...')));
                        final url = await _pickAndUploadImage();
                        if (url != null) {
                          _photoUrlController.text = url;
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gambar berhasil diunggah')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengunggah gambar'), backgroundColor: Colors.red));
                        }
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Unggah dari Galeri'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _photoUrlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(labelText: 'URL Foto', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18))), hintText: 'Masukkan URL gambar'),
                    onChanged: (_) {
                      setState(() {});
                    },
                    validator: (value) => (value?.trim().isEmpty ?? true) ? 'URL foto harus diisi' : null,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18)))),
                    minLines: 4,
                    maxLines: 6,
                    validator: (value) => (value?.trim().isEmpty ?? true) ? 'Deskripsi harus diisi' : null,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _saveItem,
                      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _isSubmitting
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(widget.item == null ? 'Tambah' : 'Simpan'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
