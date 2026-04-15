import 'package:flutter/material.dart';
import 'login_page.dart'; // Import halaman login

void main() {
  runApp(const EdukasiApp());
}

class EdukasiApp extends StatelessWidget {
  const EdukasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EdukasiIn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1E88E5),
        scaffoldBackgroundColor: const Color(0xFF1E88E5), // Background biru
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Tema untuk ElevatedButton agar seragam di semua halaman
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
      // Ubah halaman pertama menjadi Login
      home: const LoginPage(),
    );
  }
}