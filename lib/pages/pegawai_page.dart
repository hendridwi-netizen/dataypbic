import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pegawai_form.dart';

class PegawaiPage extends StatelessWidget {
  final String unitKerja;
  const PegawaiPage({super.key, required this.unitKerja});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('pegawai')
        .where('unit_kerja', isEqualTo: unitKerja)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Data Pegawai $unitKerja'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => PegawaiForm(unitKerja: unitKerja),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Pegawai'),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('❌ Terjadi kesalahan: ${snapshot.error}'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text('📭 Belum ada pegawai di unit $unitKerja'),
              );
            }

            final docs = snapshot.data!.docs;

            docs.sort((a, b) {
              final nameA = (a['nama'] ?? '').toString();
              final nameB = (b['nama'] ?? '').toString();
              return nameA.compareTo(nameB);
            });

            return Card(
              elevation: 3,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Nama')),
                    DataColumn(label: Text('Jabatan')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('KPI')),
                    DataColumn(label: Text('Prestasi')),
                    DataColumn(label: Text('Materi/Cara Kerja')),
                    DataColumn(label: Text('Aksi')),
                  ],
                  rows: docs.map((d) {
                    final m = d.data() as Map<String, dynamic>;
                    return DataRow(cells: [
                      DataCell(Text(m['nama'] ?? '-')),
                      DataCell(Text(m['jabatan'] ?? '-')),
                      DataCell(Text(m['status'] ?? '-')),
                      DataCell(Text('${m['KPI'] ?? '-'}')),
                      DataCell(Text(m['prestasi'] ?? '-')),
                      DataCell(Text(m['materi_pembelajaran'] ?? '-')),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => PegawaiForm(
                                  unitKerja: unitKerja,
                                  docId: d.id,
                                  initialData: m,
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final konfirmasi = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Hapus Data Pegawai'),
                                  content: const Text(
                                      'Apakah Anda yakin ingin menghapus data ini?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Batal')),
                                    ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Hapus')),
                                  ],
                                ),
                              );
                              if (konfirmasi == true) {
                                await FirebaseFirestore.instance
                                    .collection('pegawai')
                                    .doc(d.id)
                                    .delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Data pegawai dihapus')),
                                );
                              }
                            },
                          ),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
