import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class AdminContentPage extends StatefulWidget {
  const AdminContentPage({super.key});

  @override
  State<AdminContentPage> createState() => _AdminContentPageState();
}

class _AdminContentPageState extends State<AdminContentPage> {
  bool _isLoading = true;
  String _filterStatus = 'Semua';
  List<Map<String, dynamic>> _contents = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContents();
  }

  Future<void> _loadContents() async {
    setState(() {
      _isLoading = true;
      _contents = [];
      _error = null;
    });
    try {
      final items = await FirestoreService.getContents();
      _contents = items.where((c) {
        final statusValue = (c['status'] ?? '').toString().toLowerCase();
        if (_filterStatus.toLowerCase() == 'semua') return true;
        return statusValue == _filterStatus.toLowerCase();
      }).toList();
      if (_contents.isEmpty) {
        debugPrint('Firestore getContents returned ${items.length} items, after filters: ${_contents.length}');
      }
    } catch (e, st) {
      _contents = [];
      _error = e.toString();
      debugPrint('Error loading contents: $e');
      debugPrint('$st');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await FirestoreService.updateContentStatus(id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Konten di-set $status')));
      await _loadContents();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memperbarui status')));
    }
  }

  Widget _buildFilterChips() {
    const statuses = ['Semua', 'pending', 'approved', 'rejected'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: statuses.map((s) {
            final label = s == 'Semua' ? 'Semua' : s[0].toUpperCase() + s.substring(1);
            final selected = s.toLowerCase() == _filterStatus.toLowerCase();
            
            Color getColor() {
              if (s == 'Semua') return Colors.blue;
              if (s == 'pending') return Colors.amber;
              if (s == 'approved') return Colors.green;
              return Colors.red;
            }

            return Padding(
              padding: EdgeInsets.only(right: statuses.last == s ? 0 : 10),
              child: Material(
                child: InkWell(
                  onTap: () async {
                    setState(() => _filterStatus = s);
                    await _loadContents();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? LinearGradient(colors: [getColor(), getColor().withValues(alpha: 0.8)])
                          : LinearGradient(colors: [Colors.white, Colors.grey.shade50]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? getColor() : Colors.grey.shade200,
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selected ? getColor().withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
                          blurRadius: selected ? 8 : 4,
                          offset: Offset(0, selected ? 2 : 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected) ...[
                          Icon(Icons.check_circle, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContentCard(Map<String, dynamic> c) {
    final status = (c['status'] ?? '').toString().toLowerCase();
    
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.schedule;
    String statusLabel = 'Pending';
    
    if (status == 'approved') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusLabel = 'Approved';
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusLabel = 'Rejected';
    } else if (status == 'pending') {
      statusColor = Colors.amber;
      statusIcon = Icons.pending_actions;
      statusLabel = 'Pending';
    }

    // Safely format createdAt for display (handle Timestamp, DateTime, or string)
    final rawCreated = c['createdAt'];
    String createdAtText = '';
    if (rawCreated != null) {
      if (rawCreated is DateTime) {
        createdAtText = rawCreated.toLocal().toString();
      } else {
        try {
          final maybeDate = (rawCreated as dynamic).toDate();
          if (maybeDate is DateTime) createdAtText = maybeDate.toLocal().toString();
        } catch (_) {
          createdAtText = rawCreated.toString();
        }
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan title dan status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['title'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Description
                if ((c['description'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      c['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                
                // Metadata
                if ((c['mentorName'] ?? '').toString().isNotEmpty || (c['createdAt'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        if ((c['mentorName'] ?? '').toString().isNotEmpty) ...[
                          Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              c['mentorName'] ?? '',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (createdAtText.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                createdAtText,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                
                // Action Buttons
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (status != 'approved')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateStatus(c['id'].toString(), 'approved'),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    if (status != 'approved' && status != 'rejected') const SizedBox(width: 10),
                    if (status != 'rejected')
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatus(c['id'].toString(), 'rejected'),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          'Validasi Konten',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Review dan validasi konten dari mentor',
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
                padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Filter Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                    if (!_isLoading && _error == null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _loadContents,
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
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildFilterChips(),
              ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.blue.shade600),
                      const SizedBox(height: 16),
                      const Text('Memuat konten...', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                )
              else if (_contents.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Container(
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
                          child: Icon(Icons.inbox, color: Colors.blue.shade600, size: 30),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tidak ada konten',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tidak ada konten untuk divalidasi pada kategori ini',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Error: $_error',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadContents,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Muat Ulang', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: RefreshIndicator(
                    onRefresh: _loadContents,
                    color: Colors.blue.shade600,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _contents.length,
                      itemBuilder: (context, i) => _buildContentCard(_contents[i]),
                    ),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}
