import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminCreateGuru extends StatefulWidget {
  const AdminCreateGuru({super.key});

  @override
  State<AdminCreateGuru> createState() => _AdminCreateGuruState();
}

class _AdminCreateGuruState extends State<AdminCreateGuru> {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loading = false;

  final List<String> _unitKerjaList = const [
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

  String? _selectedUnit;

  String _generatePassword(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#%!&';
    final rand = Random.secure();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _createGuruAccount() async {
    final nama = _namaController.text.trim();
    final email = _emailController.text.trim();

    if (nama.isEmpty || email.isEmpty || _selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Nama, email, dan unit harus diisi."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _loading = true);

    try {
      final password = _generatePassword(10);

      // 1. Buat akun auth Firebase
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // 2. Simpan role & unit ke Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'nama': nama,
        'email': email,
        'role': 'pegawai',
        'unit': _selectedUnit,
        'created_at': FieldValue.serverTimestamp(),
      });

      // 3. (Opsional) Tambahkan juga ke koleksi pegawai
      await FirebaseFirestore.instance.collection('pegawai').doc(uid).set({
        'nama': nama,
        'unit_kerja': _selectedUnit,
        'jabatan': '',
        'status': 'Aktif',
        'KPI': 0,
        'prestasi': '',
        'materi_pembelajaran': '',
        'foto_url': null,
        'created_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "Akun guru berhasil dibuat!\nPassword: $password\nUnit: $_selectedUnit"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 6),
      ));

      _namaController.clear();
      _emailController.clear();
      setState(() => _selectedUnit = null);

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Gagal membuat akun: ${e.message}"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Akun Guru / Pegawai"),
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
                labelText: "Nama Guru",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email Guru",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedUnit,
              items: _unitKerjaList.map((unit) {
                return DropdownMenuItem(
                  value: unit,
                  child: Text(unit),
                );
              }).toList(),
              decoration: const InputDecoration(
                labelText: "Unit Kerja",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _selectedUnit = value);
              },
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: Text(_loading ? "Sedang membuat akun..." : "Buat Akun"),
                onPressed: _loading ? null : _createGuruAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
