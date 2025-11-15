import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pimpinan_penilaian_page.dart';

class PimpinanDashboard extends StatelessWidget {
  const PimpinanDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final unit = data["unit"] ?? "-";

        return Scaffold(
          appBar: AppBar(
            title: Text("Penilaian KPI - Unit $unit"),
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: "Logout",
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),

          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("pegawai")
                .where("unit_kerja", isEqualTo: unit)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(
                  child: Text("Belum ada guru di unit ini."),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final guru = docs[index];
                  final nama = guru["nama"];

                  return Card(
                    child: ListTile(
                      title: Text(nama),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PimpinanPenilaianPage(
                              guruId: guru.id,
                              guruName: nama,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
