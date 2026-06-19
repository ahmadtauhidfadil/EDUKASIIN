import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'register_page.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(); // Controller Password
  
  bool _isPasswordVisible = false;
  bool _isLoading = false; // State untuk loading indikator

  // 3. Fungsi Login dengan Firebase Auth dan Firestore
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Tampilkan loading
      });

      try {
        final userCredential = await AuthService.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        final userDoc = await FirestoreService.getUserProfile(userCredential.user!.uid);

        if (!userDoc.exists || userDoc.data() == null) {
          throw Exception('Profil pengguna tidak ditemukan.');
        }

        final userData = userDoc.data()!;
        final role = (userData['role']?.toString() ?? 'lansia').toLowerCase().trim();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selamat datang, ${userData['name']}! Role: $role')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              userId: userCredential.user!.uid,
              userName: userData['name'] ?? '',
              userEmail: userData['email'] ?? _emailController.text.trim(),
              userRole: role,
            ),
          ),
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        _showError(e.message ?? 'Gagal masuk. Periksa koneksi internet dan coba lagi.');
      } on Exception catch (e) {
        if (!mounted) return;
        _showError(e.toString().replaceAll('Exception: ', ''));
      } catch (e) {
        if (!mounted) return;
        _showError('Gagal masuk. Periksa email dan password Anda.');
      } finally {
        setState(() {
          _isLoading = false; // Matikan loading
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 50),
                const Icon(Icons.school, size: 80, color: Color(0xFF1E88E5)),
                const SizedBox(height: 16),
                const Text("Selamat Datang di EdukasiIn", 
                  textAlign: TextAlign.center, 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                    if (!value.contains('@')) return 'Masukkan format email yang valid';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _passwordController, // Controller ditambahkan di sini
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
                    if (value.length < 6) return 'Password minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Tampilkan loading spinner jika sedang proses login
                _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text('MASUK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Belum punya akun? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
                      },
                      child: const Text("Daftar di sini", style: TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}