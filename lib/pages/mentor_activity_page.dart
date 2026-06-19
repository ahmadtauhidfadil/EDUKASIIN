import 'package:flutter/material.dart';

class MentorActivityPage extends StatelessWidget {
  const MentorActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      {'user': 'Siti', 'activity': 'Menyelesaikan modul Berkebun 4', 'time': '1 jam lalu'},
      {'user': 'Joko', 'activity': 'Mengajukan pertanyaan pada sesi Tanya Mentor', 'time': '2 jam lalu'},
      {'user': 'Rina', 'activity': 'Mengikuti kelas Zoom bahasa', 'time': 'Kemarin'},
    ];

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
            child: const Text('Pantau Aktivitas', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final item = activities[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 1,
                  child: ListTile(
                    title: Text(item['user']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(item['activity']!),
                        const SizedBox(height: 8),
                        Text(item['time']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Detail aktivitas ${item['user']} akan segera hadir.')));
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
