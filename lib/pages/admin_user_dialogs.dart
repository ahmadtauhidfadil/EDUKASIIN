// ignore_for_file: unused_field

import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class AddUserDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const AddUserDialog({super.key, required this.onSuccess});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  String _role = 'lansia';
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirestoreService.createUser({
        'name': _name,
        'email': _email,
        'password': _password,
        'role': _role,
      });
      if (!mounted) return;
      widget.onSuccess();
      Navigator.of(context).pop();
      _showSnackBar('Pengguna berhasil ditambahkan', Colors.green);
    } catch (_) {
      _showSnackBar('Gagal terhubung ke server', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Pengguna'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nama Lengkap', hintText: 'Masukkan nama'),
                validator: (v) => (v?.isEmpty ?? true) ? 'Nama tidak boleh kosong' : null,
                onSaved: (v) => _name = v ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email', hintText: 'Masukkan email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v?.isEmpty ?? true) ? 'Email tidak boleh kosong' : (!v!.contains('@') ? 'Format email salah' : null),
                onSaved: (v) => _email = v ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password', hintText: 'Masukkan password'),
                obscureText: true,
                validator: (v) => (v?.isEmpty ?? true) ? 'Password tidak boleh kosong' : (v!.length < 6 ? 'Password minimal 6 karakter' : null),
                onSaved: (v) => _password = v ?? '',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Tipe Akun'),
                items: const [
                  DropdownMenuItem(value: 'lansia', child: Text('Lansia')),
                  DropdownMenuItem(value: 'mentor', child: Text('Mentor')),
                ],
                onChanged: (value) => setState(() => _role = value ?? 'lansia'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

class EditUserDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onSuccess;

  const EditUserDialog({super.key, required this.user, required this.onSuccess});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _email;
  String _password = '';
  late String _role;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _name = widget.user['name'] ?? '';
    _email = widget.user['email'] ?? '';
    _role = widget.user['role'] ?? 'lansia';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirestoreService.updateUser(widget.user['id'].toString(), {
        'name': _name,
        'email': _email,
        'role': _role,
      });
      if (!mounted) return;
      widget.onSuccess();
      Navigator.of(context).pop();
      _showSnackBar('Pengguna berhasil diperbarui', Colors.green);
    } catch (_) {
      _showSnackBar('Gagal terhubung ke server', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Pengguna'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (v) => (v?.isEmpty ?? true) ? 'Nama tidak boleh kosong' : null,
                onSaved: (v) => _name = v ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v?.isEmpty ?? true) ? 'Email tidak boleh kosong' : (!v!.contains('@') ? 'Format email salah' : null),
                onSaved: (v) => _email = v ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password Baru (Kosongkan jika tidak ingin ubah)', hintText: 'Opsional'),
                obscureText: true,
                onSaved: (v) => _password = v ?? '',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Tipe Akun'),
                items: const [
                  DropdownMenuItem(value: 'lansia', child: Text('Lansia')),
                  DropdownMenuItem(value: 'mentor', child: Text('Mentor')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) => setState(() => _role = value ?? 'lansia'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Perbarui'),
        ),
      ],
    );
  }
}

class DeleteUserDialog extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onSuccess;

  const DeleteUserDialog({super.key, required this.user, required this.onSuccess});

  Future<void> _deleteUser(BuildContext context) async {
    try {
      await FirestoreService.deleteUser(user['id'].toString());
      if (!context.mounted) return;
      onSuccess();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengguna berhasil dihapus'), backgroundColor: Colors.green));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal terhubung ke server'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hapus Pengguna'),
      content: Text('Apakah Anda yakin ingin menghapus ${user['name']}?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => _deleteUser(context),
          child: const Text('Hapus', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
