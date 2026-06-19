import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class ChatPage extends StatefulWidget {
  /// If [conversationId] is provided, load that conversation. Otherwise
  /// a conversation will be created between current user and selected mentor.
  final String? conversationId;
  final String? initialMentorId;
  final String? initialMentorName;
  final bool isMentor;
  final String? partnerName;

  const ChatPage({
    super.key,
    this.conversationId,
    this.initialMentorId,
    this.initialMentorName,
    this.isMentor = false,
    this.partnerName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _chatController = TextEditingController();
  String? _conversationId;
  String? _mentorId;
  String? _mentorName;
  String? _partnerName;
  bool _isMentor = false;
  String? _userId;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _messagesStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _mentorsStream;

  @override
  void initState() {
    super.initState();
    _mentorId = widget.initialMentorId;
    _mentorName = widget.initialMentorName;
    _partnerName = widget.partnerName;
    _isMentor = widget.isMentor;
    _conversationId = widget.conversationId;
    _userId = FirebaseAuth.instance.currentUser?.uid ?? 'anon_user';
    if (_conversationId != null) {
      _messagesStream = ChatService.streamMessages(_conversationId!);
    }
    _mentorsStream = _loadMentorsStream();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _loadMentorsStream() {
    final fs = FirebaseFirestore.instance;
    // Prefer a dedicated 'mentors' collection if present, otherwise fall back
    // to a 'users' collection filtered by role == 'mentor'. This keeps the
    // UI working with common schemas without dummy data.
    final mentorsColl = fs.collection('mentors');
    // We'll attempt to listen to 'mentors' first; callers can detect empty.
    // To keep a single stream, merge by checking existence at runtime: here
    // we simply return mentors collection stream and the UI will fallback
    // to users-role if mentors are empty.
    return mentorsColl.snapshots();
  }

  Future<void> _openConversationWith(String mentorId, String mentorName) async {
    final userId = _userId ?? FirebaseAuth.instance.currentUser?.uid ?? 'anon_user';
    final convId = await ChatService.getOrCreateConversation(userId, mentorId);
    setState(() {
      _conversationId = convId;
      _mentorId = mentorId;
      _mentorName = mentorName;
      _messagesStream = ChatService.streamMessages(convId);
    });
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _conversationId == null) return;
    final senderId = _userId ?? 'anon_user';
    final senderRole = _isMentor ? 'mentor' : 'user';
    await ChatService.sendMessage(_conversationId!, senderId, senderRole, text);
    _chatController.clear();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Widget _buildMessageTile(Map<String, dynamic> msg) {
    final isUser = (msg['senderRole'] ?? 'user') == 'user';
    final text = msg['text'] ?? '';
    final ts = msg['createdAt'];
    String time = '';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue.shade700 : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
              ),
              child: Text(text, style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 15)),
            ),
            if (time.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mentorCard(String id, String name, String subject, {Map<String, dynamic>? extra}) {
    final isSelected = _mentorId == id;
    return GestureDetector(
      onTap: () async {
        await _openConversationWith(id, name);
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
          Text(subject, style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey.shade700, fontSize: 12)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isMentor ? 'Jawab Pertanyaan' : 'Chat Mentor';
    final subtitle = _isMentor ? 'Lihat dan jawab pertanyaan dari lansia.' : 'Konsultasi materi secara pribadi dengan mentor berpengalaman.';
    final topName = _isMentor ? (_partnerName ?? 'Lansia') : (_mentorName ?? 'Pilih Mentor');
    final topSubtitle = _isMentor
        ? 'Buka percakapan dan balas pertanyaan lansia.'
        : _mentorId != null
            ? 'Spesialis ${_mentorName ?? ''}'
            : 'Pilih mentor untuk memulai chat';

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
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
                                  Text(topName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(topSubtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
                        if (!_isMentor) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 92,
                            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: _mentorsStream,
                              builder: (context, mentorsSnap) {
                                if (mentorsSnap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                                final mentorsDocs = mentorsSnap.data?.docs ?? [];
                                if (mentorsDocs.isEmpty) {
                                  return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                    future: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'mentor').get(),
                                    builder: (context, usersSnap) {
                                      if (usersSnap.connectionState == ConnectionState.waiting) return const SizedBox();
                                      final users = usersSnap.data?.docs ?? [];
                                      if (users.isEmpty) return const Center(child: Text('Tidak ada mentor tersedia.'));
                                      return ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: users.length,
                                        itemBuilder: (context, index) {
                                          final d = users[index].data();
                                          final id = users[index].id;
                                          final name = (d['name'] ?? d['fullName'] ?? 'Mentor') as String;
                                          final subject = (d['subject'] ?? d['specialty'] ?? '') as String;
                                          return _mentorCard(id, name, subject);
                                        },
                                      );
                                    },
                                  );
                                }
                                return ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: mentorsDocs.length,
                                  itemBuilder: (context, index) {
                                    final d = mentorsDocs[index].data();
                                    final id = mentorsDocs[index].id;
                                    final name = (d['name'] ?? d['fullName'] ?? 'Mentor') as String;
                                    final subject = (d['subject'] ?? d['specialty'] ?? '') as String;
                                    return _mentorCard(id, name, subject, extra: d);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: _messagesStream == null
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 6))]),
                                child: Text(
                                  _isMentor
                                      ? 'Belum ada pertanyaan dari lansia.'
                                      : _mentorName != null
                                          ? 'Belum ada pesan. Tanyakan sesuatu ke $_mentorName untuk memulai chat.'
                                          : 'Pilih mentor dari daftar di atas, lalu tulis pertanyaan di bawah.',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: _messagesStream,
                              builder: (context, snap) {
                                if (snap.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final docs = snap.data?.docs ?? [];
                                if (docs.isEmpty) {
                                  return Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 6))]),
                                      child: Text(
                                        _isMentor
                                            ? 'Belum ada pertanyaan dari lansia.'
                                            : 'Belum ada pesan. Tanyakan sesuatu ke ${_mentorName ?? 'mentor'} untuk memulai chat.',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                }
                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                                  itemCount: docs.length,
                                  itemBuilder: (context, index) {
                                    final data = docs[index].data();
                                    return _buildMessageTile(data);
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))]),
                    child: TextField(
                      controller: _chatController,
                      decoration: InputDecoration(
                        hintText: _isMentor ? 'Jawab pertanyaan lansia...' : 'Ketik pertanyaanmu...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.shade600, boxShadow: [BoxShadow(color: Colors.blue.shade200.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))]),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
