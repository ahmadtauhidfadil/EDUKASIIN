import 'package:flutter/material.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  // GlobalKey untuk validasi form [cite: 32]
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Feedback via SnackBar [cite: 33]
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil ${_nameController.text} Berhasil Disimpan!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Edit Profil")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form( // Widget Form [cite: 31]
          key: _formKey,
          child: Column(
            children: [
              TextFormField( // Aturan validasi 1 [cite: 32]
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nama Lengkap"),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Nama tidak boleh kosong';
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField( // Aturan validasi 2 [cite: 32]
                decoration: const InputDecoration(labelText: "Bio (Minimal 6 Karakter)"),
                validator: (value) {
                  if (value == null || value.length < 6) return 'Minimal 6 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text("Simpan Data"),
              )
            ],
          ),
        ),
      ),
    );
  }
}