import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class YayasanPage extends StatelessWidget {
  const YayasanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Dashboard Yayasan YPBIC'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat datang, ${user?.email ?? 'Yayasan'} 👋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rekap Data Pegawai Seluruh Unit',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(child: _StatCard(title: 'Total Pegawai', query: null)),
                SizedBox(width: 16),
                Expanded(child: _StatCard(title: 'Pegawai Aktif', query: 'Aktif')),
                SizedBox(width: 16),
                Expanded(child: _StatCard(title: 'Nonaktif', query: 'Nonaktif')),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Data Pegawai',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Expanded(child: _PegawaiTable()),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// KOMPONEN: Kartu Statistik
/// ===============================================================
class _StatCard extends StatelessWidget {
  final String title;
  final String? query; // null = total, "Aktif"/"Nonaktif"
  const _StatCard({required this.title, this.query});

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> ref =
        FirebaseFirestore.instance.collection('pegawai');

    if (query != null) {
      ref = ref.where('status', isEqualTo: query);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: ref.snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1565C0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bar_chart, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('$count',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ===============================================================
/// KOMPONEN: Tabel Data Pegawai
/// ===============================================================
class _PegawaiTable extends StatelessWidget {
  const _PegawaiTable();

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance.collection('pegawai').snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Terjadi kesalahan: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Belum ada data pegawai.'));
        }

        // Ambil semua data
        final docs = snapshot.data!.docs;

        // Sort manual biar tidak perlu Firestore index
        docs.sort((a, b) {
          final unitA = (a['unit_kerja'] ?? '').toString();
          final unitB = (b['unit_kerja'] ?? '').toString();
          if (unitA != unitB) return unitA.compareTo(unitB);
          return (a['nama'] ?? '').toString().compareTo((b['nama'] ?? '').toString());
        });

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Unit')),
                DataColumn(label: Text('Nama')),
                DataColumn(label: Text('Jabatan')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('KPI')),
                DataColumn(label: Text('Prestasi')),
                DataColumn(label: Text('Materi/Cara Kerja')),
              ],
              rows: docs.map((d) {
                final m = d.data() as Map<String, dynamic>;
                return DataRow(
                  cells: [
                    DataCell(Text(m['unit_kerja'] ?? '-')),
                    DataCell(Text(m['nama'] ?? '-')),
                    DataCell(Text(m['jabatan'] ?? '-')),
                    DataCell(Text(m['status'] ?? '-')),
                    DataCell(Text('${m['KPI'] ?? '-'}')),
                    DataCell(Text(m['prestasi'] ?? '-')),
                    DataCell(Text(m['materi_pembelajaran'] ?? '-')),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
