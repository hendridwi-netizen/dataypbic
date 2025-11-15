import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

// ====================================================================
// HALAMAN LIST KPI (8 ASPEK)
// ====================================================================
class GuruKpiPage extends StatelessWidget {
  const GuruKpiPage({super.key});

  final List<Map<String, dynamic>> aspekList = const [
    {"id": "1_pengembangan_profesi", "nama": "Pengembangan Profesi"},
    {"id": "2_perencanaan", "nama": "Perencanaan"},
    {"id": "3_pelaksanaan_pembelajaran", "nama": "Pelaksanaan Pembelajaran"},
    {"id": "4_evaluasi_proses", "nama": "Evaluasi Proses"},
    {"id": "5_profesionalisme", "nama": "Profesionalisme"},
    {"id": "6_komunikasi_interaksi", "nama": "Komunikasi dan Interaksi"},
    {"id": "7_professional_development", "nama": "Professional Development"},
    {"id": "8_personal_development", "nama": "Personal Development"},
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Anda belum login.")),
      );
    }

    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("KPI Guru"),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: aspekList.length,
        itemBuilder: (context, index) {
          final aspek = aspekList[index];

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("pegawai")
                .doc(uid)
                .collection("kpi")
                .doc(aspek['id'])
                .snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;

              final nilai = data?["nilai"] ?? "-";
              final status = data?["status"] ?? "Belum Dinilai";
              final catatan = data?["catatan_penilai"] ?? "-";
              final evidenceCount = data?["evidence_count"] ?? 0;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(
                    aspek["nama"],
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Nilai: $nilai\n"
                      "Status: $status\n"
                      "Catatan: $catatan\n"
                      "Evidence: $evidenceCount file",
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      color: Color(0xFF1565C0)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailKpiGuruPage(
                          aspekId: aspek['id'],
                          aspekNama: aspek['nama'],
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
  }
}

// ====================================================================
// DETAIL KPI (UPLOAD EVIDENCE)
// ====================================================================
class DetailKpiGuruPage extends StatefulWidget {
  final String aspekId;
  final String aspekNama;

  const DetailKpiGuruPage({
    super.key,
    required this.aspekId,
    required this.aspekNama,
  });

  @override
  State<DetailKpiGuruPage> createState() => _DetailKpiGuruPageState();
}

class _DetailKpiGuruPageState extends State<DetailKpiGuruPage> {
  bool _uploading = false;

  Future<void> _uploadEvidence() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;

    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null) return;

    final file = result.files.first;
    final fileBytes = file.bytes!;
    final fileName = file.name;

    setState(() => _uploading = true);

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child("kpi_evidence/$uid/${widget.aspekId}/${DateTime.now().millisecondsSinceEpoch}_$fileName");

      final uploadTask = await storageRef.putData(fileBytes);
      final fileUrl = await uploadTask.ref.getDownloadURL();

      // Simpan metadata ke Firestore
      await FirebaseFirestore.instance
          .collection("pegawai")
          .doc(uid)
          .collection("kpi")
          .doc(widget.aspekId)
          .collection("evidence")
          .add({
        "file_name": fileName,
        "file_url": fileUrl,
        "uploaded_at": FieldValue.serverTimestamp(),
      });

      // Tambah counter evidence
      await FirebaseFirestore.instance
          .collection("pegawai")
          .doc(uid)
          .collection("kpi")
          .doc(widget.aspekId)
          .set({
        "evidence_count": FieldValue.increment(1)
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Evidence berhasil diunggah."),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Gagal upload: $e"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.aspekNama),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _uploadEvidence,
        label: Text(_uploading ? "Mengunggah..." : "Upload Evidence"),
        icon: const Icon(Icons.upload_file),
        backgroundColor: const Color(0xFF1565C0),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // =======================
            // HEADER NILAI & STATUS
            // =======================
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("pegawai")
                  .doc(uid)
                  .collection("kpi")
                  .doc(widget.aspekId)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;

                final nilai = data?["nilai"] ?? "-";
                final status = data?["status"] ?? "Belum Dinilai";
                final catatan = data?["catatan_penilai"] ?? "-";

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Aspek: ${widget.aspekNama}",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text("Nilai: $nilai"),
                    Text("Status: $status"),
                    Text("Catatan Penilai: $catatan"),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),

            // =======================
            // LIST EVIDENCE
            // =======================
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("pegawai")
                    .doc(uid)
                    .collection("kpi")
                    .doc(widget.aspekId)
                    .collection("evidence")
                    .orderBy("uploaded_at", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text("Belum ada evidence."),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data =
                          docs[index].data() as Map<String, dynamic>;

                      final fileUrl = data["file_url"];
                      final fileName = data["file_name"];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.insert_drive_file,
                              color: Colors.blue),
                          title: Text(fileName),
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new,
                                color: Colors.green),
                            onPressed: () {
                              html.window.open(fileUrl, "_blank");
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
