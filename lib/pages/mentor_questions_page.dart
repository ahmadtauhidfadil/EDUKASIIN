import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'chat_page.dart';

class MentorQuestionsPage extends StatefulWidget {
  final String mentorId;

  const MentorQuestionsPage({super.key, required this.mentorId});

  @override
  State<MentorQuestionsPage> createState() => _MentorQuestionsPageState();
}

class _MentorQuestionsPageState extends State<MentorQuestionsPage> {
  String _mentorName = '';
  String _mentorSpecialty = '';
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _loadMentorInfo();
  }

  Future<void> _loadMentorInfo() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('mentors').doc(widget.mentorId).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _mentorName = (data?['name'] ?? data?['fullName'] ?? 'Mentor') as String;
          _mentorSpecialty = (data?['subject'] ?? data?['specialty'] ?? 'Spesialis') as String;
        });
      } else {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.mentorId).get();
        if (userDoc.exists) {
          final data = userDoc.data();
          setState(() {
            _mentorName = (data?['name'] ?? data?['fullName'] ?? 'Mentor') as String;
            _mentorSpecialty = (data?['subject'] ?? data?['specialty'] ?? 'Spesialis') as String;
          });
        }
      }
    } catch (e) {
      // Fallback default values already set
    }
  }

  Future<void> _openConversationWithUser(String userId, String userName) async {
    try {
      final convId = await ChatService.getOrCreateConversation(userId, widget.mentorId);
      setState(() {
        _selectedUserId = userId;
      });
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(conversationId: convId, isMentor: true, partnerName: userName),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuka percakapan')));
    }
  }

  Widget _userCard(String id, String name, {Map<String, dynamic>? extra}) {
    final isSelected = _selectedUserId == id;
    return GestureDetector(
      onTap: () async {
        await _openConversationWithUser(id, name);
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade700 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.blue.shade100, blurRadius: 12, offset: const Offset(0, 6))]
              : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(name, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Text('Lansia', style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey.shade700, fontSize: 12)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade800,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Jawab Pertanyaan', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Lihat dan jawab pertanyaan dari lansia.', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 18, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(radius: 26, backgroundColor: Colors.blue.shade50, child: const Icon(Icons.person, color: Colors.blue, size: 28)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_mentorName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(_mentorSpecialty, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                              child: const Text('Online', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 92,
                          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'lansia').snapshots(),
                            builder: (context, snap) {
                              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                              final docs = snap.data?.docs ?? [];
                              if (docs.isEmpty) return const Center(child: Text('Belum ada lansia terdaftar.'));
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.only(left: 4, right: 8),
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  final d = docs[index].data();
                                  final id = docs[index].id;
                                  final name = (d['name'] ?? d['fullName'] ?? 'Lansia') as String;
                                  final extra = d;
                                  return _userCard(id, name, extra: extra);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: ChatService.streamConversationsForMentor(widget.mentorId),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final docs = snap.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))]),
                              child: const Text('Belum ada pertanyaan dari lansia.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data();
                            final convId = docs[index].id;
                            final userId = data['userId'] ?? '';
                            final lastMessage = data['lastMessage'] ?? '';
                            final ts = data['lastUpdated'] as Timestamp?;
                            String time = '';
                            if (ts != null) {
                              final dt = ts.toDate();
                              time = '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                            }

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatPage(
                                      conversationId: convId,
                                      isMentor: true,
                                      partnerName: userId.toString(),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.blue.shade50,
                                      child: const Icon(Icons.person, color: Colors.blue, size: 28),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(userId.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                          const SizedBox(height: 6),
                                          Text(
                                            lastMessage,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      time,
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
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
