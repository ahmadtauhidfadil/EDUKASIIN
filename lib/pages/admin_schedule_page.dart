import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class AdminSchedulePage extends StatefulWidget {
  const AdminSchedulePage({super.key});

  @override
  State<AdminSchedulePage> createState() => _AdminSchedulePageState();
}

class _AdminSchedulePageState extends State<AdminSchedulePage> {
  bool _isLoading = true;
  bool _isScheduleLoading = false;
  String? _error;
  String? _scheduleError;
  List<Map<String, dynamic>> _mentors = [];
  List<Map<String, dynamic>> _schedules = [];
  String? _selectedMentorId;

  @override
  void initState() {
    super.initState();
    _loadMentors();
  }

  Future<void> _loadMentors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final mentors = await FirestoreService.getUsers(role: 'mentor');
      if (!mounted) return;
      setState(() {
        _mentors = mentors;
        if (_selectedMentorId == null && mentors.isNotEmpty) {
          _selectedMentorId = mentors.first['id']?.toString();
        }
      });
      if (_selectedMentorId != null) {
        await _loadSchedulesForMentor(_selectedMentorId!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data mentor. Coba lagi nanti.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSchedulesForMentor(String mentorId) async {
    setState(() {
      _isScheduleLoading = true;
      _scheduleError = null;
      _schedules = [];
    });

    try {
      final schedules = await FirestoreService.getSchedulesForMentor(mentorId);
      if (!mounted) return;
      setState(() {
        _schedules = schedules;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scheduleError = 'Gagal memuat jadwal mentor. Coba lagi nanti.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isScheduleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedMentor = _mentors.firstWhere(
      (mentor) => mentor['id']?.toString() == _selectedMentorId,
      orElse: () => {},
    );
    final selectedMentorName = selectedMentor['name']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade600, Colors.blue.shade900],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Atur Jadwal Mentor',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Kelola jadwal kelas dan bimbingan untuk semua mentor',
                          style: TextStyle(fontSize: 14, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pilih Mentor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    if (!_isLoading && _error == null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _loadMentors,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.refresh, color: Colors.blue.shade600, size: 20),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildMentorList(),
              ),
              const SizedBox(height: 32),
              if (_selectedMentorId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jadwal ${selectedMentorName.isNotEmpty ? selectedMentorName : 'Mentor'}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      if (_isScheduleLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_scheduleError != null)
                        _buildErrorState(_scheduleError!, () => _loadSchedulesForMentor(_selectedMentorId!))
                      else if (_schedules.isEmpty)
                        _buildEmptyState()
                      else
                        Column(children: _schedules.map((item) => _buildScheduleCard(item)).toList()),
                    ],
                  ),
                )
              else if (!_isLoading && _error == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSelectMentorState(),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildErrorState(_error!, _loadMentors),
                ),
              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue.shade600),
            const SizedBox(height: 16),
            const Text('Memuat daftar mentor...', style: TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }

    if (_mentors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tidak ada mentor terdaftar saat ini',
                style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _mentors.length,
        itemBuilder: (context, index) {
          final mentor = _mentors[index];
          final mentorId = mentor['id']?.toString() ?? '';
          final name = mentor['name']?.toString() ?? 'Mentor';
          final email = mentor['email']?.toString() ?? '';
          final selected = mentorId == _selectedMentorId;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMentorId = mentorId;
              });
              _loadSchedulesForMentor(mentorId);
            },
                child: Container(
              width: 160,
              margin: EdgeInsets.only(right: index == _mentors.length - 1 ? 0 : 12),
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(colors: [Colors.blue.shade600, Colors.blue.shade800])
                    : LinearGradient(colors: [Colors.white, Colors.grey.shade50]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? Colors.blue.shade600 : Colors.grey.shade200, width: selected ? 2 : 1),
                boxShadow: [
                      BoxShadow(
                        color: selected ? Colors.blue.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04),
                        blurRadius: selected ? 12 : 8,
                        offset: Offset(0, selected ? 4 : 2),
                      ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                            color: selected ? Colors.white.withValues(alpha: 0.2) : Colors.blue.shade100,
                      ),
                      child: Icon(Icons.person, color: selected ? Colors.white : Colors.blue.shade600, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: selected ? Colors.white : Colors.black87,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Dipilih', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_today, color: Colors.blue.shade600, size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada jadwal',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Mentor ini belum membuat jadwal bimbingan atau kelas',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadSchedulesForMentor(_selectedMentorId!),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cek Ulang', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectMentorState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.touch_app, color: Colors.purple.shade600, size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pilih mentor terlebih dahulu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Scroll ke atas dan pilih mentor untuk melihat jadwal mereka',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> item) {
    final title = item['title']?.toString() ?? 'Jadwal';
    final scheduleTime = item['scheduleTime']?.toString() ?? '';
    final mode = item['mode']?.toString() ?? '';
    final location = item['location']?.toString() ?? '';

    IconData modeIcon = Icons.calendar_today;
    Color modeColor = Colors.blue.shade600;

    if (mode.toLowerCase().contains('online') || mode.toLowerCase().contains('zoom')) {
      modeIcon = Icons.videocam;
      modeColor = Colors.purple.shade600;
    } else if (mode.toLowerCase().contains('offline')) {
      modeIcon = Icons.location_on;
      modeColor = Colors.orange.shade600;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Edit jadwal "$title" akan segera hadir.')),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: modeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(modeIcon, color: modeColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (scheduleTime.isNotEmpty) ...[
                            Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                scheduleTime,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: modeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              mode,
                              style: TextStyle(fontSize: 11, color: modeColor, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.place, size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
