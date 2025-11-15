import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pegawai_page.dart';
import 'admin_create_guru.dart';
import 'admin_create_pimpinan.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  final List<String> _unitKerjaList = const [
    'TK',
    'SD',
    'SMP',
    'SMA',
    'Staff/Manajemen',
    'Pramubakti',
    'Maintenance',
    'Security',
    'Marbot',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text('Dashboard Admin SIP_YPBIC'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Selamat datang, Admin 👋",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // ============================================================
            // TOMBOL BUAT AKUN GURU
            // ============================================================
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminCreateGuru()),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text("Buat Akun Guru / Pegawai"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              ),
            ),
            const SizedBox(height: 16),

            // ============================================================
            // TOMBOL BUAT AKUN PIMPINAN
            // ============================================================
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminCreatePimpinan()),
                );
              },
              icon: const Icon(Icons.supervisor_account),
              label: const Text("Buat Akun Pimpinan Unit"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              "Manajemen Data Pegawai per Unit",
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // ============================================================
            // GRID UNIT KERJA
            // ============================================================
            Expanded(
              child: GridView.builder(
                itemCount: _unitKerjaList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,        // 3 kolom
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  final unit = _unitKerjaList[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PegawaiPage(unitKerja: unit),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Center(
                        child: Text(
                          unit,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
