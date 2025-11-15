import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pegawai_form.dart';

class UnitKerjaPage extends StatelessWidget {
  final String unitNama;
  const UnitKerjaPage({super.key, required this.unitNama});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('pegawai')
        .where('unit_kerja', isEqualTo: unitNama)
        .orderBy('nama')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Data Pegawai $unitNama'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Pegawai'),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => PegawaiForm(unitKerja: unitNama),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Belum ada data pegawai.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Foto')),
                    DataColumn(label: Text('Nama')),
                    DataColumn(label: Text('Jabatan')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('KPI')),
                    DataColumn(label: Text('Prestasi')),
                    DataColumn(label: Text('Materi/Cara Kerja')),
                    DataColumn(label: Text('Aksi')),
                  ],
                  rows: docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return DataRow(
                      cells: [
                        DataCell(
                          data['foto_url'] != null
                              ? CircleAvatar(backgroundImage: NetworkImage(data['foto_url']), radius: 20)
                              : const Icon(Icons.person, color: Colors.grey),
                        ),
                        DataCell(Text(data['nama'] ?? '-')),
                        DataCell(Text(data['jabatan'] ?? '-')),
                        DataCell(Text(data['status'] ?? '-')),
                        DataCell(Text('${data['KPI'] ?? '-'}')),
                        DataCell(Text(data['prestasi'] ?? '-')),
                        DataCell(Text(data['materi_pembelajaran'] ?? '-')),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => PegawaiForm(
                                    unitKerja: unitNama,
                                    docId: d.id,
                                    initialData: data,
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Hapus Data'),
                                    content: Text('Yakin ingin menghapus ${data['nama']}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await FirebaseFirestore.instance
                                      .collection('pegawai')
                                      .doc(d.id)
                                      .delete();
                                }
                              },
                            ),
                          ],
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
