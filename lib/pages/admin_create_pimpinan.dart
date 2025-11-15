import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCreatePimpinan extends StatefulWidget {
  const AdminCreatePimpinan({super.key});

  @override
  State<AdminCreatePimpinan> createState() => _AdminCreatePimpinanState();
}

class _AdminCreatePimpinanState extends State<AdminCreatePimpinan> {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedUnit;
  bool _loading = false;

  final List<String> _unitList = const [
    "TK",
    "SD",
    "SMP",
    "SMA",
    "Staff/Manajemen",
    "Pramubakti",
    "Maintenance",
    "Security",
    "Marbot",
  ];

  // Generate Password Acak
  String _generatePassword(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#%!&';
    final rand = Random.secure();
    return List.generate(length, (i) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _createPimpinan() async {
    if (_namaController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Nama, email, dan unit harus diisi."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _loading = true);

    try {
      final password = _generatePassword(10);

      // Buat akun Firebase Auth
      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: _emailController.text.trim(), password: password);

      final uid = userCred.user!.uid;

      // Simpan data user pimpinan di Firestore
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "nama": _namaController.text.trim(),
        "email": _emailController.text.trim(),
        "role": "pimpinan",
        "unit": _selectedUnit,
        "created_at": FieldValue.serverTimestamp()
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "Akun pimpinan berhasil dibuat!\nPassword: $password\nUnit: $_selectedUnit"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 6),
      ));

      _namaController.clear();
      _emailController.clear();
      setState(() => _selectedUnit = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal membuat akun pimpinan: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Akun Pimpinan Unit"),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: "Nama Pimpinan",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email Pimpinan",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedUnit,
              decoration: const InputDecoration(
                labelText: "Unit Penilaian",
                border: OutlineInputBorder(),
              ),
              items: _unitList.map((u) {
                return DropdownMenuItem(value: u, child: Text(u));
              }).toList(),
              onChanged: (v) => setState(() => _selectedUnit = v),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: Text(_loading ? "Menyimpan..." : "Buat Akun Pimpinan"),
                onPressed: _loading ? null : _createPimpinan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 17),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
