import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MentorUsersPage extends StatefulWidget {
  final String mentorId;

  const MentorUsersPage({super.key, required this.mentorId});

  @override
  State<MentorUsersPage> createState() => _MentorUsersPageState();
}

class _MentorUsersPageState extends State<MentorUsersPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _mentees = [];

  @override
  void initState() {
    super.initState();
    _fetchMentees();
  }

  Future<void> _fetchMentees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get('get_mentor_mentees.php', {
        'mentor_id': widget.mentorId.toString(),
      });
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        final rawList = data['data'] as List<dynamic>;
        _mentees = rawList
            .map((item) => {
                  'id': item['id'],
                  'name': item['name'],
                  'email': item['email'],
                  'role': item['role'],
                })
            .toList();
      } else {
        _error = data['message']?.toString() ?? 'Gagal memuat daftar lansia.';
      }
    } catch (e) {
      _error = 'Tidak dapat terhubung ke server.';
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
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade600]),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: const Text('Daftar Lansia', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari lansia',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    readOnly: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pencarian akan segera tersedia.')));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jadwal bimbingan akan segera tersedia.')));
                  },
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Jadwal'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _mentees.length,
                        itemBuilder: (context, index) {
                          final item = _mentees[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 1,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: const Icon(Icons.person, color: Colors.blue)),
                              title: Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(item['email'] as String),
                              trailing: Text(item['role'] as String, style: const TextStyle(color: Colors.blue)),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Detail ${item['name']} akan segera hadir.')));
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
