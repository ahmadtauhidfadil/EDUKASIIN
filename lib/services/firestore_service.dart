import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  static Future<void> createUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data);
  }

  static Future<void> createUser(Map<String, dynamic> data) async {
    await _firestore.collection('users').add(data);
  }

  static Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  static Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  static Future<List<Map<String, dynamic>>> getUsers({String? role, String? query}) async {
    Query<Map<String, dynamic>> queryRef = _firestore.collection('users');
    if (role != null && role.isNotEmpty) {
      queryRef = queryRef.where('role', isEqualTo: role);
    }

    final snapshot = await queryRef.get();
    final lowerQuery = query?.trim().toLowerCase();

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? '',
            'email': data['email'] ?? '',
            'role': data['role'] ?? '',
          };
        })
        .where((user) {
          if (lowerQuery == null || lowerQuery.isEmpty) return true;
          final name = user['name']?.toString().toLowerCase() ?? '';
          final email = user['email']?.toString().toLowerCase() ?? '';
          return name.contains(lowerQuery) || email.contains(lowerQuery);
        })
        .toList();
  }

  static Future<Map<String, int>> getUserCounts() async {
    final snapshot = await _firestore.collection('users').get();
    int lansia = 0;
    int mentor = 0;
    for (final doc in snapshot.docs) {
      final role = doc.data()['role']?.toString().toLowerCase();
      if (role == 'lansia') {
        lansia += 1;
      } else if (role == 'mentor') {
        mentor += 1;
      }
    }
    return {'lansia': lansia, 'mentor': mentor};
  }

  static Future<List<Map<String, dynamic>>> getMinatBakatItems({String? query}) async {
    final snapshot = await _firestore.collection('minat_bakat').get();
    final lowerQuery = query?.trim().toLowerCase();

    final items = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'title': data['title'] ?? '',
        'description': data['description'] ?? '',
        'photoUrl': data['photoUrl'] ?? '',
        'videoUrl': data['videoUrl'] ?? '',
        'modules': data['modules'] ?? [],
        'participants': data['participants'] ?? [],
        'createdAt': data['createdAt'],
        'updatedAt': data['updatedAt'],
      };
    }).where((item) {
      if (lowerQuery == null || lowerQuery.isEmpty) return true;
      final title = item['title']?.toString().toLowerCase() ?? '';
      final description = item['description']?.toString().toLowerCase() ?? '';
      return title.contains(lowerQuery) || description.contains(lowerQuery);
    }).toList();

    items.sort((a, b) {
      final aTs = a['createdAt'] is Timestamp ? (a['createdAt'] as Timestamp).toDate() : DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(1970);
      final bTs = b['createdAt'] is Timestamp ? (b['createdAt'] as Timestamp).toDate() : DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(1970);
      return bTs.compareTo(aTs);
    });

    return items;
  }

  static Future<void> createMinatBakat(Map<String, dynamic> data) async {
    await _firestore.collection('minat_bakat').add(data);
  }

  static Future<void> updateMinatBakat(String id, Map<String, dynamic> data) async {
    await _firestore.collection('minat_bakat').doc(id).update(data);
  }

  static Future<void> deleteMinatBakat(String id) async {
    await _firestore.collection('minat_bakat').doc(id).delete();
  }

  static Future<Map<String, dynamic>?> getMinatBakatById(String id) async {
    final doc = await _firestore.collection('minat_bakat').doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data() ?? {};
    return {
      'id': doc.id,
      ...data,
    };
  }

  static Future<void> joinMinatBakatClass(String id, String userId) async {
    await _firestore.collection('minat_bakat').doc(id).set({
      'participants': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<bool> isUserJoinedMinatBakatClass(String id, String userId) async {
    final doc = await _firestore.collection('minat_bakat').doc(id).get();
    if (!doc.exists) return false;
    final data = doc.data() ?? {};
    final participants = data['participants'];
    if (participants is List) {
      return participants.map((e) => e?.toString()).contains(userId);
    }
    final enrolledUsers = data['enrolledUsers'];
    if (enrolledUsers is List) {
      return enrolledUsers.map((e) => e?.toString()).contains(userId);
    }
    return false;
  }

  static Future<void> createClass(Map<String, dynamic> data) async {
    await _firestore.collection('kelas').add(data);
  }

  static Future<List<Map<String, dynamic>>> getClassesForMentor(String mentorId) async {
    final snapshot = await _firestore.collection('kelas').where('mentorId', isEqualTo: mentorId).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'title': data['title'] ?? data['name'] ?? data['kelas'] ?? 'Kelas',
        'description': data['description'] ?? data['detail'] ?? '',
        'photoUrl': data['photoUrl'] ?? data['thumbnailUrl'] ?? '',
        'videoUrl': data['videoUrl'] ?? data['video_url'] ?? '',
        'modules': data['modules'] ?? data['module'] ?? data['modul'] ?? [],
        'mentorId': data['mentorId'] ?? data['mentor_id'] ?? '',
        'status': data['status'] ?? '',
        'createdAt': data['createdAt'],
        'updatedAt': data['updatedAt'],
      };
    }).toList();
  }

  static Future<Map<String, dynamic>?> getClassById(String id) async {
    final doc = await _firestore.collection('kelas').doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data() ?? {};
    return {
      'id': doc.id,
      'title': data['title'] ?? data['name'] ?? data['kelas'] ?? 'Kelas',
      'description': data['description'] ?? data['detail'] ?? '',
      'photoUrl': data['photoUrl'] ?? data['thumbnailUrl'] ?? '',
      'videoUrl': data['videoUrl'] ?? data['video_url'] ?? '',
      'modules': data['modules'] ?? data['module'] ?? data['modul'] ?? [],
      'mentorId': data['mentorId'] ?? data['mentor_id'] ?? '',
      'status': data['status'] ?? '',
      'createdAt': data['createdAt'],
      'updatedAt': data['updatedAt'],
    };
  }

  static Future<void> updateClass(String id, Map<String, dynamic> data) async {
    await _firestore.collection('kelas').doc(id).set(data, SetOptions(merge: true));
  }

  static Future<int> getMinatBakatCount() async {
    final snapshot = await _firestore.collection('minat_bakat').get();
    return snapshot.size;
  }

  static Future<int> _getCollectionCount(List<String> collectionNames) async {
    for (final collectionName in collectionNames) {
      final snapshot = await _firestore.collection(collectionName).get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.size;
      }
    }
    return 0;
  }

  static Future<int> getClassCount() async {
    return await _getCollectionCount(['kelas', 'classes', 'class']);
  }

  static Future<Map<String, int>> getDashboardCounts() async {
    final userCounts = await getUserCounts();
    final classCount = await getClassCount();
    return {
      'lansia': userCounts['lansia'] ?? 0,
      'mentor': userCounts['mentor'] ?? 0,
      'kelas': classCount,
    };
  }

  static Future<List<Map<String, dynamic>>> getContents({String? status}) async {
    Query<Map<String, dynamic>> query = _firestore.collection('contents');
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status.toLowerCase());
    }
    final snapshot = await query.get();
    final items = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'title': data['title'] ?? '',
        'description': data['description'] ?? '',
        'mentorId': data['mentorId'] ?? '',
        'mentorName': data['mentorName'] ?? data['mentor_name'] ?? '',
        'photoUrl': data['photoUrl'] ?? data['thumbnailUrl'] ?? data['thumbnail'] ?? '',
        'videoUrl': data['videoUrl'] ?? data['video_url'] ?? data['video'] ?? '',
        'status': (data['status'] ?? '').toString(),
        'createdAt': data['createdAt'],
        'updatedAt': data['updatedAt'],
      };
    }).toList();

    items.sort((a, b) {
      final aTs = a['createdAt'] is Timestamp ? (a['createdAt'] as Timestamp).toDate() : DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(1970);
      final bTs = b['createdAt'] is Timestamp ? (b['createdAt'] as Timestamp).toDate() : DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(1970);
      return bTs.compareTo(aTs);
    });

    return items;
  }

  static Future<List<Map<String, dynamic>>> getSchedulesForMentor(String mentorId) async {
    const scheduleCollections = ['jadwal', 'schedule', 'schedules', 'kelas', 'classes', 'class'];
    for (final collectionName in scheduleCollections) {
      final snapshot = await _firestore.collection(collectionName).where('mentorId', isEqualTo: mentorId).get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map(_mapScheduleDocument).toList();
      }
    }

    for (final collectionName in scheduleCollections) {
      final snapshot = await _firestore.collection(collectionName).where('mentor_id', isEqualTo: mentorId).get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map(_mapScheduleDocument).toList();
      }
    }

    return [];
  }

  static Map<String, dynamic> _mapScheduleDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return {
      'id': doc.id,
      'title': data['title'] ?? data['name'] ?? data['kelas'] ?? data['className'] ?? 'Jadwal',
      'description': data['description'] ?? data['detail'] ?? '',
      'scheduleTime': data['time'] ?? data['date'] ?? data['waktu'] ?? data['scheduleTime'] ?? '',
      'mode': data['mode'] ?? data['type'] ?? data['status'] ?? data['category'] ?? 'Tidak Diketahui',
      'location': data['location'] ?? data['tempat'] ?? '',
      'mentorId': data['mentorId'] ?? data['mentor_id'] ?? '',
    };
  }

  static Future<void> updateContentStatus(String id, String status) async {
    await _firestore.collection('contents').doc(id).update({'status': status.toLowerCase(), 'updatedAt': FieldValue.serverTimestamp()});
  }

  static Future<void> createContent(Map<String, dynamic> data) async {
    final normalized = Map<String, dynamic>.from(data);
    normalized['status'] = (normalized['status'] ?? 'pending').toString().toLowerCase();
    normalized['createdAt'] = FieldValue.serverTimestamp();
    normalized['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('contents').add(normalized);
  }

  static Future<List<Map<String, dynamic>>> getInappropriatePosts() async {
    const forumCollections = ['forum', 'forums', 'diskusi', 'discussion', 'posts', 'discussions'];
    
    for (final collectionName in forumCollections) {
      try {
        final snapshot = await _firestore
            .collection(collectionName)
            .where('isFlagged', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();
        
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'collectionName': collectionName,
              'title': data['title'] ?? data['subject'] ?? 'Forum Post',
              'content': data['content'] ?? data['message'] ?? data['body'] ?? '',
              'authorId': data['authorId'] ?? data['userId'] ?? data['postedBy'] ?? '',
              'authorName': data['authorName'] ?? data['userName'] ?? 'Anonymous',
              'flagReason': data['flagReason'] ?? data['reason'] ?? 'Konten kurang pantas',
              'createdAt': data['createdAt'],
              'flaggedAt': data['flaggedAt'],
              'comments': data['comments'] ?? 0,
            };
          }).toList();
        }
      } catch (e) {
        print('Error querying collection $collectionName: $e');
      }
    }
    
    return [];
  }

  static Future<void> deleteForumPost(String collectionName, String postId) async {
    await _firestore.collection(collectionName).doc(postId).delete();
  }

  static Future<void> approveFlaggedPost(String collectionName, String postId) async {
    await _firestore.collection(collectionName).doc(postId).update({
      'isFlagged': false,
      'flagReason': null,
      'flaggedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetch classes that a specific user is enrolled in
  /// Tries multiple collection names and enrollment data structures
  static Future<List<Map<String, dynamic>>> getEnrolledClassesForUser(String userId) async {
    const classCollections = ['kelas', 'classes', 'class', 'minat_bakat'];
    final enrolledClasses = <Map<String, dynamic>>[];

    // Try each possible collection name
    for (final collectionName in classCollections) {
      try {
        // Method 1: Check if class has participants/enrolledUsers array with userId
        final snapshot = await _firestore
            .collection(collectionName)
            .where('participants', arrayContains: userId)
            .get();

        if (snapshot.docs.isNotEmpty) {
          for (final doc in snapshot.docs) {
            final data = doc.data();
            enrolledClasses.add({
              'id': doc.id,
              'title': data['title'] ?? data['name'] ?? data['kelas'] ?? 'Kelas',
              'description': data['description'] ?? data['detail'] ?? '',
              'progressText': _getProgressText(data),
              'progressValue': _getProgressValue(data),
              'desc': data['description'] ?? data['detail'] ?? 'Deskripsi kelas',
              'modules': data['modules'] ?? data['module'] ?? data['modul'] ?? data['moduls'] ?? [],
              'completedModules': data['completedModules'] ?? data['selesai'] ?? 0,
              'mentorId': data['mentorId'] ?? data['mentor_id'] ?? '',
              'mentorName': data['mentorName'] ?? data['mentor_name'] ?? 'Mentor',
              'createdAt': data['createdAt'],
              'updatedAt': data['updatedAt'],
            });
          }
          if (enrolledClasses.isNotEmpty) return enrolledClasses;
        }
      } catch (e) {
        print('Error querying $collectionName with participants array: $e');
      }

      try {
        // Method 2: Check if class has enrolledUsers array with userId
        final snapshot = await _firestore
            .collection(collectionName)
            .where('enrolledUsers', arrayContains: userId)
            .get();

        if (snapshot.docs.isNotEmpty) {
          for (final doc in snapshot.docs) {
            final data = doc.data();
            enrolledClasses.add({
              'id': doc.id,
              'title': data['title'] ?? data['name'] ?? data['kelas'] ?? 'Kelas',
              'description': data['description'] ?? data['detail'] ?? '',
              'progressText': _getProgressText(data),
              'progressValue': _getProgressValue(data),
              'desc': data['description'] ?? data['detail'] ?? 'Deskripsi kelas',
              'modules': data['modules'] ?? data['module'] ?? data['modul'] ?? data['moduls'] ?? [],
              'completedModules': data['completedModules'] ?? data['selesai'] ?? 0,
              'mentorId': data['mentorId'] ?? data['mentor_id'] ?? '',
              'mentorName': data['mentorName'] ?? data['mentor_name'] ?? 'Mentor',
              'createdAt': data['createdAt'],
              'updatedAt': data['updatedAt'],
            });
          }
          if (enrolledClasses.isNotEmpty) return enrolledClasses;
        }
      } catch (e) {
        print('Error querying $collectionName with enrolledUsers array: $e');
      }
    }

    // Fallback: Get all classes (if no enrollment info found)
    // This returns empty list if no enrolled classes found, which is correct
    return enrolledClasses;
  }

  /// Helper: Extract progress text from class data
  static String _getProgressText(Map<String, dynamic> data) {
    final completed = data['completedModules'] ?? data['selesai'] ?? 0;
    final modules = data['modules'] ?? data['modul'] ?? data['moduls'];
    final total = modules is List ? modules.length : (modules as num? ?? 10);
    return '$completed dari $total modul selesai';
  }

  /// Helper: Calculate progress value (0.0 - 1.0) from class data
  static double _getProgressValue(Map<String, dynamic> data) {
    final completed = (data['completedModules'] ?? data['selesai'] ?? 0) as num;
    final modules = data['modules'] ?? data['modul'] ?? data['moduls'];
    final total = modules is List ? modules.length : (modules as num? ?? 10);
    if (total == 0) return 0.0;
    return (completed / total).clamp(0.0, 1.0).toDouble();
  }

  // ======================= FORUM / DISCUSSIONS =======================

  /// Fetch all discussions ordered by createdAt descending
  static Stream<List<Map<String, dynamic>>> streamDiscussions() {
    return _firestore
        .collection('discussions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'userId': data['userId'] ?? '',
          'userName': data['userName'] ?? 'User',
          'title': data['title'] ?? '',
          'message': data['message'] ?? '',
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        };
      }).toList();
    });
  }

  static Future<List<Map<String, dynamic>>> getDiscussions() async {
    try {
      final snapshot = await _firestore
          .collection('discussions')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'userId': data['userId'] ?? '',
          'userName': data['userName'] ?? 'User',
          'title': data['title'] ?? '',
          'message': data['message'] ?? '',
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching discussions: $e');
      return [];
    }
  }

  /// Create new discussion
  static Future<void> createDiscussion(String userId, String userName, String title, String message) async {
    try {
      await _firestore.collection('discussions').add({
        'userId': userId,
        'userName': userName,
        'title': title,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating discussion: $e');
      rethrow;
    }
  }

  /// Delete discussion
  static Future<void> deleteDiscussion(String docId) async {
    try {
      await _firestore.collection('discussions').doc(docId).delete();
    } catch (e) {
      print('Error deleting discussion: $e');
      rethrow;
    }
  }

  static Stream<List<Map<String, dynamic>>> streamDiscussionComments(String discussionId) {
    return _firestore
        .collection('discussions')
        .doc(discussionId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'userId': data['userId'] ?? '',
          'userName': data['userName'] ?? 'Pengguna',
          'message': data['message'] ?? '',
          'createdAt': data['createdAt'],
        };
      }).toList();
    });
  }

  static Future<void> addDiscussionComment(
    String discussionId,
    String userId,
    String userName,
    String message,
  ) async {
    try {
      final commentRef = _firestore
          .collection('discussions')
          .doc(discussionId)
          .collection('comments');

      await commentRef.add({
        'userId': userId,
        'userName': userName,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('discussions').doc(discussionId).update({
        'commentCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding discussion comment: $e');
      rethrow;
    }
  }

  // ======================= MODULE SCHEDULE MANAGEMENT =======================

  /// Get all schedules for a specific class
  static Future<Map<int, Map<String, dynamic>>> getSchedulesByClassId(String classId) async {
    try {
      final snapshot = await _firestore
          .collection('schedules')
          .where('classId', isEqualTo: classId)
          .get();

      final scheduleMap = <int, Map<String, dynamic>>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final moduleIndex = data['moduleIndex'] as int? ?? -1;
        if (moduleIndex >= 0) {
          scheduleMap[moduleIndex] = {
            'id': doc.id,
            'classId': data['classId'] ?? '',
            'moduleIndex': moduleIndex,
            'moduleName': data['moduleName'] ?? '',
            'scheduleTime': data['scheduleTime'] ?? '',
            'createdAt': data['createdAt'],
            'updatedAt': data['updatedAt'],
          };
        }
      }
      return scheduleMap;
    } catch (e) {
      print('Error fetching schedules for class $classId: $e');
      return {};
    }
  }

  /// Save or update schedule for a specific module in a class
  /// If schedule exists, it will be updated; otherwise, a new one will be created
  static Future<String> saveSchedule(
    String classId,
    int moduleIndex,
    String moduleName,
    String scheduleTime,
  ) async {
    try {
      // Check if schedule already exists for this moduleIndex
      final existing = await _firestore
          .collection('schedules')
          .where('classId', isEqualTo: classId)
          .where('moduleIndex', isEqualTo: moduleIndex)
          .limit(1)
          .get();

      final data = {
        'classId': classId,
        'moduleIndex': moduleIndex,
        'moduleName': moduleName,
        'scheduleTime': scheduleTime,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (existing.docs.isNotEmpty) {
        // Update existing schedule
        final docId = existing.docs.first.id;
        await _firestore.collection('schedules').doc(docId).update(data);
        return docId;
      } else {
        // Create new schedule
        data['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _firestore.collection('schedules').add(data);
        return docRef.id;
      }
    } catch (e) {
      print('Error saving schedule: $e');
      rethrow;
    }
  }

  /// Delete schedule for a specific module in a class
  static Future<void> deleteSchedule(String classId, int moduleIndex) async {
    try {
      final snapshot = await _firestore
          .collection('schedules')
          .where('classId', isEqualTo: classId)
          .where('moduleIndex', isEqualTo: moduleIndex)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await _firestore.collection('schedules').doc(snapshot.docs.first.id).delete();
      }
    } catch (e) {
      print('Error deleting schedule: $e');
      rethrow;
    }
  }

  /// Delete all schedules for a class
  static Future<void> deleteAllSchedulesForClass(String classId) async {
    try {
      final snapshot = await _firestore
          .collection('schedules')
          .where('classId', isEqualTo: classId)
          .get();

      for (final doc in snapshot.docs) {
        await _firestore.collection('schedules').doc(doc.id).delete();
      }
    } catch (e) {
      print('Error deleting all schedules for class $classId: $e');
      rethrow;
    }
  }

  // ======================= SCHEDULE MIGRATION =======================

  /// Migrate scheduleTime from modules array to schedules collection
  /// This function will:
  /// 1. Scan all classes in 'kelas' collection
  /// 2. For each module with scheduleTime, create a schedule document
  /// 3. Remove scheduleTime from the modules array
  /// 4. Return migration statistics
  static Future<Map<String, dynamic>> migrateScheduleTimesToSchedulesCollection() async {
    try {
      final Map<String, dynamic> stats = {
        'totalClasses': 0,
        'classesWithSchedules': 0,
        'schedulesCreated': 0,
        'schedulesSkipped': 0,
        'errors': 0,
        'errorMessages': <String>[],
      };

      // Get all classes from 'kelas' collection
      final classesSnapshot = await _firestore.collection('kelas').get();
      stats['totalClasses'] = classesSnapshot.size;

      for (final classDoc in classesSnapshot.docs) {
        try {
          final classData = classDoc.data();
          final modules = classData['modules'] as List? ?? [];
          bool hasSchedules = false;
          int schedulesInThisClass = 0;

          // Iterate through each module
          for (int moduleIndex = 0; moduleIndex < modules.length; moduleIndex++) {
            final module = modules[moduleIndex] as Map<String, dynamic>? ?? {};
            final scheduleTime = module['scheduleTime']?.toString() ?? '';
            final moduleName = module['name']?.toString() ?? 'Modul';

            // If scheduleTime exists, migrate it
            if (scheduleTime.isNotEmpty) {
              try {
                // Check if schedule already exists in new collection
                final existingSchedule = await _firestore
                    .collection('schedules')
                    .where('classId', isEqualTo: classDoc.id)
                    .where('moduleIndex', isEqualTo: moduleIndex)
                    .limit(1)
                    .get();

                // Only create if doesn't exist
                if (existingSchedule.docs.isEmpty) {
                  await _firestore.collection('schedules').add({
                    'classId': classDoc.id,
                    'moduleIndex': moduleIndex,
                    'moduleName': moduleName,
                    'scheduleTime': scheduleTime,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  stats['schedulesCreated'] = (stats['schedulesCreated'] as int) + 1;
                  schedulesInThisClass += 1;
                  hasSchedules = true;
                } else {
                  stats['schedulesSkipped'] = (stats['schedulesSkipped'] as int) + 1;
                }
              } catch (e) {
                stats['errors'] = (stats['errors'] as int) + 1;
                stats['errorMessages'].add('Class ${classDoc.id}, Module $moduleIndex: $e');
              }
            }
          }

          // If this class had schedules, update the count
          if (hasSchedules) {
            stats['classesWithSchedules'] = (stats['classesWithSchedules'] as int) + 1;
          }
        } catch (e) {
          stats['errors'] = (stats['errors'] as int) + 1;
          stats['errorMessages'].add('Class ${classDoc.id}: $e');
        }
      }

      return stats;
    } catch (e) {
      print('Error during schedule migration: $e');
      rethrow;
    }
  }

  /// Remove scheduleTime from all modules in all classes
  /// Call this AFTER verifying all schedules have been migrated
  static Future<Map<String, dynamic>> removeScheduleTimeFromModules() async {
    try {
      final Map<String, dynamic> stats = {
        'totalClasses': 0,
        'classesUpdated': 0,
        'modulesUpdated': 0,
        'errors': 0,
        'errorMessages': <String>[],
      };

      // Get all classes from 'kelas' collection
      final classesSnapshot = await _firestore.collection('kelas').get();
      stats['totalClasses'] = classesSnapshot.size;

      for (final classDoc in classesSnapshot.docs) {
        try {
          final classData = classDoc.data();
          final modules = classData['modules'] as List? ?? [];
          List<Map<String, dynamic>> updatedModules = [];
          bool hasChanges = false;

          // Remove scheduleTime from each module
          for (final module in modules) {
            final moduleMap = Map<String, dynamic>.from(module as Map? ?? {});
            if (moduleMap.containsKey('scheduleTime')) {
              moduleMap.remove('scheduleTime');
              hasChanges = true;
              stats['modulesUpdated'] = (stats['modulesUpdated'] as int) + 1;
            }
            updatedModules.add(moduleMap);
          }

          // Only update if there were changes
          if (hasChanges) {
            await _firestore.collection('kelas').doc(classDoc.id).update({
              'modules': updatedModules,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            stats['classesUpdated'] = (stats['classesUpdated'] as int) + 1;
          }
        } catch (e) {
          stats['errors'] = (stats['errors'] as int) + 1;
          stats['errorMessages'].add('Class ${classDoc.id}: $e');
        }
      }

      return stats;
    } catch (e) {
      print('Error removing scheduleTime from modules: $e');
      rethrow;
    }
  }

  /// Verify migration by checking for orphaned scheduleTime in modules
  static Future<Map<String, dynamic>> verifyMigration() async {
    try {
      final Map<String, dynamic> stats = {
        'totalClasses': 0,
        'classesWithOrphanedSchedules': 0,
        'orphanedSchedules': 0,
        'orphanedDetails': <Map<String, dynamic>>[],
      };

      // Get all classes from 'kelas' collection
      final classesSnapshot = await _firestore.collection('kelas').get();
      stats['totalClasses'] = classesSnapshot.size;

      for (final classDoc in classesSnapshot.docs) {
        final classData = classDoc.data();
        final modules = classData['modules'] as List? ?? [];
        bool hasOrphaned = false;

        for (int moduleIndex = 0; moduleIndex < modules.length; moduleIndex++) {
          final module = modules[moduleIndex] as Map<String, dynamic>? ?? {};
          final scheduleTime = module['scheduleTime']?.toString() ?? '';

          if (scheduleTime.isNotEmpty) {
            hasOrphaned = true;
            stats['orphanedSchedules'] = (stats['orphanedSchedules'] as int) + 1;
            stats['orphanedDetails'].add({
              'classId': classDoc.id,
              'className': classData['title'] ?? 'Unknown',
              'moduleIndex': moduleIndex,
              'moduleName': module['name'] ?? 'Module',
              'scheduleTime': scheduleTime,
            });
          }
        }

        if (hasOrphaned) {
          stats['classesWithOrphanedSchedules'] = (stats['classesWithOrphanedSchedules'] as int) + 1;
        }
      }

      return stats;
    } catch (e) {
      print('Error verifying migration: $e');
      rethrow;
    }
  }
}
