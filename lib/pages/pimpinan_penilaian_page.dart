import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PimpinanPenilaianPage extends StatelessWidget {
  final String guruId;
  final String guruName;

  const PimpinanPenilaianPage({
    super.key,
    required this.guruId,
    required this.guruName,
  });

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
    return Scaffold(
      appBar: AppBar(
        title: Text("Nilai KPI: $guruName"),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: aspekList.length,
        itemBuilder: (context, index) {
          final aspek = aspekList[index];

          return Card(
            child: ListTile(
              title: Text(aspek["nama"]),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _PimpinanDetailNilai(
                      guruId: guruId,
                      aspekId: aspek["id"],
                      aspekNama: aspek["nama"],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PimpinanDetailNilai extends StatefulWidget {
  final String guruId;
  final String aspekId;
  final String aspekNama;

  const _PimpinanDetailNilai({
    required this.guruId,
    required this.aspekId,
    required this.aspekNama,
  });

  @override
  State<_PimpinanDetailNilai> createState() => _PimpinanDetailNilaiState();
}

class _PimpinanDetailNilaiState extends State<_PimpinanDetailNilai> {
  final nilaiController = TextEditingController();
  final catatanController = TextEditingController();

  bool saving = false;

  Future<void> _saveNilai() async {
    final nilai = int.tryParse(nilaiController.text);

    if (nilai == null || nilai < 0 || nilai > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nilai harus 0–100"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => saving = true);

    await FirebaseFirestore.instance
        .collection("pegawai")
        .doc(widget.guruId)
        .collection("kpi")
        .doc(widget.aspekId)
        .set({
      "nilai": nilai,
      "catatan_penilai": catatanController.text,
      "status": "Dinilai",
      "updated_at": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() => saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Nilai berhasil disimpan")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.aspekNama),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Evidence Guru",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("pegawai")
                    .doc(widget.guruId)
                    .collection("kpi")
                    .doc(widget.aspekId)
                    .collection("evidence")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Text("Belum ada evidence.");
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final ev = docs[index].data() as Map<String, dynamic>;

                      return Card(
                        child: ListTile(
                          title: Text(ev["file_name"]),
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () {
                              html.window.open(ev["file_url"], "_blank");
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            TextField(
              controller: nilaiController,
              decoration: const InputDecoration(
                labelText: "Nilai (0–100)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 12),
            TextField(
              controller: catatanController,
              decoration: const InputDecoration(
                labelText: "Catatan Penilai",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: saving ? null : _saveNilai,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 14),
              ),
              child: Text(
                saving ? "Menyimpan..." : "Simpan Nilai",
                style: const TextStyle(fontSize: 18),
              ),
            )
          ],
        ),
      ),
    );
  }
}
