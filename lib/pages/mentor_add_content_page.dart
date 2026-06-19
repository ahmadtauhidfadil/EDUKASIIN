import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/firestore_service.dart';

class MentorAddContentPage extends StatefulWidget {
  final String mentorId;
  final String mentorName;

  const MentorAddContentPage({super.key, required this.mentorId, required this.mentorName});

  @override
  State<MentorAddContentPage> createState() => _MentorAddContentPageState();
}

class _MentorAddContentPageState extends State<MentorAddContentPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _isUploadingVideo = false;
  String? _pickedVideoName;

  static const String _cloudName = 'dgbczkxwg';
  static const String _uploadPreset = 'flutter_upload';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() {
        _pickedVideoName = pickedFile.name;
        _isUploadingVideo = true;
      });

      final uploadedUrl = await _uploadVideoToCloudinary(File(pickedFile.path));
      if (uploadedUrl != null) {
        _videoUrlController.text = uploadedUrl;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengunggah video. Silakan coba lagi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memilih video: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingVideo = false;
        });
      }
    }
  }

  Future<String?> _uploadVideoToCloudinary(File file) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/video/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        return body['secure_url'] as String?;
      }

      print('Cloudinary upload failed: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }

  Future<void> _submitContent() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final videoUrl = _videoUrlController.text.trim();

    if (title.isEmpty || description.isEmpty || videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul, deskripsi, dan video harus dipilih.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirestoreService.createContent({
        'title': title,
        'description': description,
        'mentorId': widget.mentorId,
        'mentorName': widget.mentorName,
        'videoUrl': videoUrl,
        'status': 'pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konten terkirim. Tunggu persetujuan admin.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim konten: ${e.toString()}')),
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Konten'),
        backgroundColor: Colors.blue.shade700,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tambahkan konten baru untuk ditinjau admin.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Judul Konten',
                hintText: 'Masukkan judul konten pembelajaran',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Deskripsi',
                hintText: 'Jelaskan konten singkat dan tujuan pembelajaran',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pilih video dari galeri',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingVideo ? null : _pickVideoFromGallery,
                    icon: const Icon(Icons.video_library),
                    label: Text(_isUploadingVideo ? 'Mengunggah...' : 'Pilih Video'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_pickedVideoName != null)
              Text('Video terpilih: $_pickedVideoName', style: const TextStyle(fontSize: 14)),
            if (_videoUrlController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Video berhasil diunggah.',
                  style: TextStyle(color: Colors.green.shade700, fontSize: 14),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting || _isUploadingVideo ? null : _submitContent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Kirim Konten', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Konten akan dikirim sebagai pending dan muncul di halaman validasi admin. Setelah ditolak atau disetujui, kamu akan menerima statusnya.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
