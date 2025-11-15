import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class PegawaiEvidencePage extends StatefulWidget {
  const PegawaiEvidencePage({super.key});

  @override
  State<PegawaiEvidencePage> createState() => _PegawaiEvidencePageState();
}

class _PegawaiEvidencePageState extends State<PegawaiEvidencePage> {
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  bool _isUploading = false;

  Future<void> _uploadEvidence() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Pilih file
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final fileBytes = file.bytes!;
    final fileName = file.name;

    setState(() => _isUploading = true);

    try {
      // Upload ke Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('evidence/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$fileName');

      final uploadTask = await storageRef.putData(fileBytes);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Simpan metadata ke Firestore
      await FirebaseFirestore.instance
          .collection('pegawai')
          .doc(user.uid)
          .collection('evidence')
          .add({
        'judul': _judulController.text.trim(),
        'deskripsi': _deskripsiController.text.trim(),
        'file_url': downloadUrl,
        'file_name': fileName,
        'tanggal_upload': FieldValue.serverTimestamp(),
        'status': 'menunggu_penilaian',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Evidence berhasil diunggah'),
          backgroundColor: Colors.green,
        ));
        _judulController.clear();
        _deskripsiController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('❌ Gagal unggah: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Anda belum login.'));
    }

    final stream = FirebaseFirestore.instance
        .collection('pegawai')
        .doc(user.uid)
        .collection('evidence')
        .orderBy('tanggal_upload', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Evidence Pegawai'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _uploadEvidence,
        icon: const Icon(Icons.upload_file),
        label: _isUploading
            ? const Text('Mengunggah...')
            : const Text('Upload Evidence'),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Form input
            TextField(
              controller: _judulController,
              decoration: const InputDecoration(
                labelText: 'Judul Evidence',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deskripsiController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            // List evidence
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(
                        child: Text('Belum ada evidence yang diunggah.'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
                          title: Text(data['judul'] ?? '-'),
                          subtitle: Text(
                              "${data['deskripsi'] ?? '-'}\nStatus: ${data['status'] ?? '-'}"),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new, color: Colors.green),
                            onPressed: () {
                              final url = data['file_url'];
                              if (url != null) {
                                // buka file di tab baru (Flutter Web)
                          
                              }
                            },
                          ),
                        ),
                      );
                    },
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