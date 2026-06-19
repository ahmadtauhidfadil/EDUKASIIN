import 'package:flutter/material.dart';
import 'pages/add_page.dart';
import 'pages/admin_content_page.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/admin_system_page.dart';
import 'pages/admin_users_page.dart';
import 'pages/chat_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/mentor_add_content_page.dart';
import 'pages/mentor_dashboard_page.dart';
import 'pages/mentor_material_page.dart';
import 'pages/mentor_questions_page.dart';
import 'pages/profile_page.dart';
import 'pages/search_page.dart';

class HomePage extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;
  final String userRole;

  const HomePage({super.key, required this.userId, required this.userName, required this.userEmail, required this.userRole});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  late List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();
    _buildPagesForRole();
  }

  void _buildPagesForRole() {
    final role = widget.userRole.toLowerCase().trim();
    if (role == 'admin') {
      _pages = [
        const AdminDashboardPage(),
        const AdminUsersPage(),
        const AdminContentPage(),
        const AdminSystemPage(),
        ProfilePage(userId: widget.userId, userName: widget.userName, userEmail: widget.userEmail, userRole: widget.userRole),
      ];
      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.group), label: 'User'),
        BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Konten'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Minat'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ];
    } else if (role == 'mentor') {
      _pages = [
        MentorDashboardPage(
          mentorId: widget.userId,
          mentorName: widget.userName,
        ),
        const MentorMaterialPage(),
        MentorQuestionsPage(mentorId: widget.userId),
        MentorAddContentPage(mentorId: widget.userId, mentorName: widget.userName),
        ProfilePage(userId: widget.userId, userName: widget.userName, userEmail: widget.userEmail, userRole: widget.userRole),
      ];
      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Kelas'),
        BottomNavigationBarItem(icon: Icon(Icons.question_answer), label: 'Tanya'),
        BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Konten'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ];
    } else if (role == 'lansia') {
      _pages = [
        DashboardPage(userId: widget.userId),
        const SearchPage(),
        AddPage(userId: widget.userId, userName: widget.userName),
        const ChatPage(),
        ProfilePage(userId: widget.userId, userName: widget.userName, userEmail: widget.userEmail, userRole: widget.userRole),
      ];
      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Jelajah'),
        BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Forum'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Tanya'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ];
    } else {
      _pages = [
        DashboardPage(userId: widget.userId),
        const SearchPage(),
        AddPage(userId: widget.userId, userName: widget.userName),
        const ChatPage(),
        ProfilePage(userId: widget.userId, userName: widget.userName, userEmail: widget.userEmail, userRole: widget.userRole),
      ];
      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Jelajah'),
        BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Forum'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Tanya'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey,
        items: _navItems,
      ),
    );
  }
}
