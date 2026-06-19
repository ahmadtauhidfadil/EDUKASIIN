// ignore_for_file: unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  static final _fs = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Ensure a conversation doc exists between a user and a mentor.
  /// Returns the conversation document id.
  static Future<String> getOrCreateConversation(String userId, String mentorId) async {
    final q = await _fs
        .collection('conversations')
        .where('userId', isEqualTo: userId)
        .where('mentorId', isEqualTo: mentorId)
        .limit(1)
        .get();

    if (q.docs.isNotEmpty) return q.docs.first.id;

    final doc = await _fs.collection('conversations').add({
      'userId': userId,
      'mentorId': mentorId,
      'lastMessage': '',
      'lastUpdated': FieldValue.serverTimestamp(),
      'unreadForMentor': 0,
      'unreadForUser': 0,
    });
    return doc.id;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamMessages(String conversationId) {
    return _fs
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  static Future<void> sendMessage(String conversationId, String senderId, String senderRole, String text) async {
    final now = FieldValue.serverTimestamp();
    final msgRef = _fs.collection('conversations').doc(conversationId).collection('messages').doc();
    await msgRef.set({
      'id': msgRef.id,
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'createdAt': now,
    });

    // update conversation meta
    final convRef = _fs.collection('conversations').doc(conversationId);
    final convSnap = await convRef.get();
    if (convSnap.exists) {
      final data = convSnap.data()!;
      int unreadForMentor = (data['unreadForMentor'] ?? 0) as int;
      int unreadForUser = (data['unreadForUser'] ?? 0) as int;
      if (senderRole == 'user') {
        unreadForMentor = unreadForMentor + 1;
      } else {
        unreadForUser = unreadForUser + 1;
      }
      await convRef.update({
        'lastMessage': text,
        'lastUpdated': now,
        'unreadForMentor': unreadForMentor,
        'unreadForUser': unreadForUser,
      });
    } else {
      await convRef.set({
        'lastMessage': text,
        'lastUpdated': now,
      }, SetOptions(merge: true));
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamConversationsForMentor(String mentorId) {
    return _fs
        .collection('conversations')
        .where('mentorId', isEqualTo: mentorId)
        .orderBy('lastUpdated', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamConversationsForUser(String userId) {
    return _fs
        .collection('conversations')
        .where('userId', isEqualTo: userId)
        .orderBy('lastUpdated', descending: true)
        .snapshots();
  }
}
