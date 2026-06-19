// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'admin_user_dialogs.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  String selectedFilter = 'Semua';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _users = [];
  int _totalUsers = 0;
  int _totalLansia = 0;
  int _totalMentor = 0;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _users = [];
    });

    try {
      final roleFilter = selectedFilter != 'Semua' ? selectedFilter.toLowerCase() : null;
      final fetchedUsers = await FirestoreService.getUsers(role: roleFilter, query: searchQuery.trim());
      final counts = await FirestoreService.getUserCounts();

      _users = fetchedUsers;
      _totalLansia = counts['lansia'] ?? 0;
      _totalMentor = counts['mentor'] ?? 0;
      _totalUsers = _totalLansia + _totalMentor;
    } catch (e) {
      _error = 'Tidak dapat terhubung ke Firebase.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _debounceSearch(String value) {
    _searchDebounce?.cancel();
    searchQuery = value;
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _fetchUsers();
    });
  }

  void _onFilterChanged(String role) {
    _searchDebounce?.cancel();
    setState(() {
      selectedFilter = role;
      searchQuery = '';
      _searchController.clear();
    });
    _fetchUsers();
  }

  Widget _buildStatsSummary() {
    final total = _totalUsers;
    final lansia = _totalLansia;
    final mentor = _totalMentor;
    final availableWidth = MediaQuery.of(context).size.width - 40;
    final cardWidth = (availableWidth - 24) / 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(width: cardWidth, child: _buildStatCard('Total', total.toString(), Colors.blue)),
          SizedBox(width: cardWidth, child: _buildStatCard('Lansia', lansia.toString(), Colors.green)),
          SizedBox(width: cardWidth, child: _buildStatCard('Mentor', mentor.toString(), Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withAlpha((0.12 * 255).round()), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.03 * 255).round()), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withAlpha((0.14 * 255).round()), borderRadius: BorderRadius.circular(12)),
                child: Icon(label == 'Total' ? Icons.group : (label == 'Lansia' ? Icons.elderly : Icons.school), color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _roleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'mentor':
        return Icons.school;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'mentor':
        return Colors.green;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  Color _roleBackgroundColor(String role) {
    return _roleColor(role).withAlpha((0.16 * 255).round());
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Cari nama atau email',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchDebounce?.cancel();
                      _searchController.clear();
                      setState(() {
                        searchQuery = '';
                      });
                      _fetchUsers();
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          onChanged: (v) {
            _debounceSearch(v);
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    const roles = ['Semua', 'Lansia', 'Mentor'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        children: roles.map((role) {
          final selected = role == selectedFilter;
          return ChoiceChip(
            label: Text(role),
            selected: selected,
            onSelected: (_) => _onFilterChanged(role),
            selectedColor: Colors.blue.shade700,
            backgroundColor: Colors.grey.shade100,
            labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserList() {
    if (_isLoading) {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(20))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(height: 16, width: double.infinity, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Container(height: 12, width: 180, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Container(height: 12, width: 100, color: Colors.grey.shade300),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
        ],
      );
    }

    if (_users.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Text('Tidak ada pengguna dengan role $selectedFilter', style: const TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _users.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: _roleBackgroundColor(user['role']!),
              radius: 28,
              child: Icon(_roleIcon(user['role']!), color: _roleColor(user['role']!), size: 22),
            ),
            title: Text(user['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(user['email']!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: _roleBackgroundColor(user['role']!), borderRadius: BorderRadius.circular(12)),
                  child: Text(user['role']!.toString().toUpperCase(), style: TextStyle(color: _roleColor(user['role']!), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    showDialog<void>(context: context, builder: (_) => EditUserDialog(user: user, onSuccess: () => _fetchUsers()));
                  },
                  child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.edit, color: Colors.blueAccent, size: 18)),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    showDialog<void>(context: context, builder: (_) => DeleteUserDialog(user: user, onSuccess: () => _fetchUsers()));
                  },
                  child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete, color: Colors.redAccent, size: 18)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => AddUserDialog(onSuccess: _fetchUsers),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Tambah User'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 140,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.08 * 255).round()), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Kelola Pengguna', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Tambah, edit, dan kelola akun pengguna dengan mudah', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildStatsSummary(),
                    const SizedBox(height: 20),
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildFilterChips(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _fetchUsers,
                        child: _buildUserList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


