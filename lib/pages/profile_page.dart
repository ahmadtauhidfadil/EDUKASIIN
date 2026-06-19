// ignore_for_file: unused_field, unused_element

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edukasin/login_page.dart';
import '../services/firestore_service.dart';
import 'help_page.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;
  final String userRole;

  const ProfilePage({super.key, required this.userId, required this.userName, required this.userEmail, required this.userRole});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
  String? _photoPath;
  String? _photoUrl;
  String _currentName = '';
  String _currentEmail = '';
  bool _canChangeEmail = false;
  bool _isSaving = false;
  bool _isUploading = false;
  bool _isUpdatingEmail = false;
  bool _isUpdatingPassword = false;
  Future<List<Map<String, dynamic>>>? _enrolledClassesFuture;
  final ImagePicker _picker = ImagePicker();

  static const String _cloudName = 'dgbczkxwg';
  static const String _uploadPreset = 'flutter_upload';

  @override
  void initState() {
    super.initState();
    _currentName = widget.userName;
    _currentEmail = widget.userEmail;
    _loadUserProfile();
    if (widget.userRole.toLowerCase() == 'lansia') {
      _enrolledClassesFuture = FirestoreService.getEnrolledClassesForUser(widget.userId);
    }
    _checkEmailUpdateAllowed();
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('profile_photo_path');
      if (path != null && path.isNotEmpty) {
        _photoPath = path;
      }
    } catch (_) {
      // ignore errors silently
    }

    try {
      final userDoc = await FirestoreService.getUserProfile(widget.userId);
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final photoUrl = data['photoUrl']?.toString();
        if (photoUrl != null && photoUrl.isNotEmpty) {
          setState(() {
            _photoUrl = photoUrl;
            _photoPath = null;
            _profileImage = null;
          });
          return;
        }
      }
      if (_photoPath != null) {
        setState(() {});
      }
    } catch (_) {
      if (mounted && _photoPath != null) {
        setState(() {});
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
      if (!mounted) return;
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        await _uploadProfilePhoto(file);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil foto')),
      );
    }
  }

  Future<void> _uploadProfilePhoto(File file) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final url = await _uploadToCloudinary(file);
      if (url == null) {
        throw Exception('Gagal mengunggah foto ke Cloudinary.');
      }

      await FirestoreService.updateUser(widget.userId, {'photoUrl': url});

      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _photoPath = null;
        _profileImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto Profil Berhasil Diperbarui')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengunggah foto: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _checkEmailUpdateAllowed() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final providerIds = user.providerData.map((provider) => provider.providerId).toList();
      setState(() {
        _canChangeEmail = providerIds.contains('password');
      });
    } catch (_) {
      setState(() {
        _canChangeEmail = false;
      });
    }
  }

  Future<String?> _uploadToCloudinary(File file) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return body['secure_url'] as String?;
      }

      print('Cloudinary upload failed: ${res.statusCode} ${res.body}');
      return null;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<void> _showEditNameDialog() async {
    final TextEditingController nameController = TextEditingController(text: _currentName);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah Nama'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Nama lengkap'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _changeName(nameController.text.trim());
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showChangeEmailDialog() async {
    final TextEditingController emailController = TextEditingController(text: _currentEmail);
    final TextEditingController passwordController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email baru'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password saat ini'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _changeEmail(emailController.text.trim(), passwordController.text.trim());
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final TextEditingController passwordController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password baru'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _changePassword(passwordController.text.trim());
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeName(String newName) async {
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama tidak boleh kosong.')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirestoreService.updateUser(widget.userId, {'name': newName});
      setState(() {
        _currentName = newName;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama berhasil diperbarui.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui nama: ${e.toString()}')));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _changeEmail(String newEmail, String currentPassword) async {
    if (newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email tidak boleh kosong.')));
      return;
    }

    setState(() {
      _isUpdatingEmail = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User belum login');
      // Reauthenticate the user before sensitive operations like updating email
      try {
        final credential = EmailAuthProvider.credential(email: user.email ?? '', password: currentPassword);
        await user.reauthenticateWithCredential(credential);
      } catch (reauthError) {
        throw Exception('Reauthentication gagal: ${reauthError.toString()}');
      }

      await user.updateEmail(newEmail);
      // Send verification to new email
      try {
        await user.sendEmailVerification();
      } catch (_) {
        // ignore sendEmailVerification errors
      }
      await FirestoreService.updateUser(widget.userId, {'email': newEmail});
      setState(() {
        _currentEmail = newEmail;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email berhasil diubah.')));
    } catch (e) {
      String msg = e.toString();
      if (e is FirebaseAuthException) {
        if (e.code == 'wrong-password') msg = 'Password salah. Silakan coba lagi.';
        if (e.code == 'requires-recent-login') msg = 'Silakan masuk ulang untuk melanjutkan.';
        if (e.code == 'operation-not-allowed') msg = 'Operasi tidak diizinkan di konfigurasi Firebase (aktifkan Email/Password pada Sign-in method).';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengubah email: $msg')));
    } finally {
      setState(() {
        _isUpdatingEmail = false;
      });
    }
  }

  Future<void> _changePassword(String newPassword) async {
    if (newPassword.isEmpty || newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password minimal 6 karakter.')));
      return;
    }

    setState(() {
      _isUpdatingPassword = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User belum login');
      await user.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengubah password: ${e.toString()}')));
    } finally {
      setState(() {
        _isUpdatingPassword = false;
      });
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Sumber Foto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Kamera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'Galeri',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade200,
      indent: 16,
      endIndent: 16,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade900, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 30),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(51),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: Colors.white,
                          backgroundImage: _photoUrl != null
                              ? NetworkImage(_photoUrl!) as ImageProvider
                              : _photoPath != null
                                  ? FileImage(File(_photoPath!)) as ImageProvider
                                  : (_profileImage != null ? FileImage(_profileImage!) : null),
                          child: (_photoUrl == null && _photoPath == null && _profileImage == null)
                              ? const Icon(Icons.person, size: 50, color: Colors.blue)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImagePickerDialog,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                              ],
                            ),
                            child: _isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.camera_alt, color: Colors.blue, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_currentName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_currentEmail, style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(widget.userRole.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.userRole.toLowerCase() == 'lansia') ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Informasi Pribadi & Akun',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),
                    ListTile(
                      title: const Text('Nama'),
                      subtitle: Text(_currentName),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: _showEditNameDialog,
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),
                    ListTile(
                      title: const Text('Email'),
                      subtitle: Text(_currentEmail),
                    ),
                    const Divider(height: 1, thickness: 1),
                    ListTile(
                      title: const Text('Password'),
                      subtitle: const Text('••••••••••••'),
                      trailing: _isUpdatingPassword
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: _showChangePasswordDialog,
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Kelas yang Diikuti',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _enrolledClassesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Gagal memuat kelas: ${snapshot.error}'),
                          );
                        }
                        final classes = snapshot.data ?? [];
                        if (classes.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Belum ada kelas yang diikuti.'),
                          );
                        }
                        return Column(
                          children: classes.map((item) {
                            return Column(
                              children: [
                                ListTile(
                                  title: Text(item['title'] ?? 'Kelas'),
                                  subtitle: Text(item['description']?.toString() ?? ''),
                                  dense: true,
                                ),
                                const Divider(height: 1, thickness: 1),
                              ],
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  // Removed several menu items per request
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'Bantuan & Dukungan',
                    subtitle: 'FAQ dan kontak dukungan',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpPage()));
                    },
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: 'Tentang Aplikasi',
                    subtitle: 'Versi 1.0.0',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'EdukasiIn',
                        applicationVersion: '1.0.0',
                        applicationLegalese: '© 2026 EdukasiIn',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Konfirmasi Keluar'),
                        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginPage()),
                                (Route<dynamic> route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            child: const Text('Keluar'),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Keluar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
