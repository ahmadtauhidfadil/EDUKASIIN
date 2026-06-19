import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (e is FirebaseException && e.code == 'duplicate-app') {
      // Firebase already initialized by another engine or module.
    } else {
      rethrow;
    }
  }

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
        // Menggunakan colorScheme agar lebih modern dan konsisten dengan Flutter terbaru
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          primary: const Color(0xFF1E88E5),
        ),
        useMaterial3: true, // Mengaktifkan Material 3 untuk tampilan lebih fresh
        scaffoldBackgroundColor: Colors.white, // Diubah ke putih agar teks di halaman lain terlihat
        
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50), // Tombol otomatis lebar
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
        ),
        
        // Memperbaiki visual input field (TextField) agar seragam di semua form
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
          ),
        ),
      ),
      // Halaman awal tetap Login
      home: const LoginPage(),
    );
  }
}
