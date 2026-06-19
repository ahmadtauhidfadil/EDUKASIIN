import 'package:flutter/material.dart';
import 'package:edukasin/detail_page.dart';
import 'package:edukasin/services/firestore_service.dart';

class EnrolledClassesPage extends StatefulWidget {
  final String userId;

  const EnrolledClassesPage({super.key, required this.userId});

  @override
  State<EnrolledClassesPage> createState() => _EnrolledClassesPageState();
}

class _EnrolledClassesPageState extends State<EnrolledClassesPage> {
  late Future<List<Map<String, dynamic>>> _enrolledClassesFuture;

  @override
  void initState() {
    super.initState();
    _enrolledClassesFuture = FirestoreService.getEnrolledClassesForUser(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelas yang Diikuti'),
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _enrolledClassesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi kesalahan saat memuat kelas',
                    style: TextStyle(color: Colors.red.shade600, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _enrolledClassesFuture = FirestoreService.getEnrolledClassesForUser(widget.userId);
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final courses = snapshot.data ?? [];

          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada kelas yang diikuti',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Daftarkan diri Anda untuk kelas apa pun untuk memulai',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: courses.length,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  final selectedCourse = Map<String, dynamic>.from(courses[index]);
                  selectedCourse['modules'] = courses[index]['modules'] ?? courses[index]['module'] ?? courses[index]['modul'] ?? courses[index]['moduls'] ?? [];
                  debugPrint('ENROLLED COURSE MODULES: ${selectedCourse['modules']}');
                  final rawModules = selectedCourse['modules'];
                  debugPrint('ENROLLED COURSE MODULES TYPE: ${rawModules.runtimeType}');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DetailPage(course: selectedCourse)),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.school, color: Colors.blue, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(courses[index]['title'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Text(courses[index]['progressText'] as String, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            value: courses[index]['progressValue'] as double,
                            minHeight: 8,
                            backgroundColor: Colors.blue.shade50,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          courses[index]['desc'] as String,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
