import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'dart:html' as html;

Future<void> exportPegawaiToExcel() async {
  try {
    final querySnapshot = await FirebaseFirestore.instance.collection('pegawai').get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Tidak ada data pegawai untuk diekspor.');
    }

    final excel = Excel.createExcel();
    final sheet = excel['Data Pegawai'];

    // Header
    sheet.appendRow([
      'Nama',
      'Unit Kerja',
      'Jabatan',
      'Status',
      'KPI',
      'Prestasi',
      'Materi Pembelajaran',
    ]);

    // Data
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      sheet.appendRow([
        data['nama'] ?? '',
        data['unit_kerja'] ?? '',
        data['jabatan'] ?? '',
        data['status'] ?? '',
        data['KPI'] ?? '',
        data['prestasi'] ?? '',
        data['materi_pembelajaran'] ?? '',
      ]);
    }

    final bytes = excel.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'Data_Pegawai_YPBIC.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  } catch (e) {
    print('❌ Gagal ekspor Excel: $e');
  }
}
