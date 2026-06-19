import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bantuan & Dukungan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FAQ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _faqItem('Bagaimana cara mendaftar?', 'Gunakan tombol Daftar pada layar utama dan isi formulir pendaftaran.'),
            const SizedBox(height: 8),
            _faqItem('Bagaimana menghubungi dukungan?', 'Gunakan detail kontak di bawah untuk menghubungi tim dukungan kami.'),
            const SizedBox(height: 20),
            const Text('Kontak Dukungan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.email, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(child: Text('support@edukasiin.app')),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: 'support@edukasiin.app'));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email disalin')));
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(child: Text('+62 812-3456-7890')),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: '+6281234567890'));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nomor telepon disalin')));
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Kontak Dukungan'),
                      content: const Text('Silakan kirim email ke support@edukasiin.app atau hubungi +62 812-3456-7890.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
                      ],
                    ),
                  );
                },
                child: const Text('Hubungi Dukungan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(answer, style: const TextStyle(color: Colors.black87)),
      ],
    );
  }
}
