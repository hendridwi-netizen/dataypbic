import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html;

class PegawaiForm extends StatefulWidget {
  final String unitKerja;
  final String? docId;
  final Map<String, dynamic>? initialData;

  const PegawaiForm({
    super.key,
    required this.unitKerja,
    this.docId,
    this.initialData,
  });

  @override
  State<PegawaiForm> createState() => _PegawaiFormState();
}

class _PegawaiFormState extends State<PegawaiForm> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _jabatanController = TextEditingController();
  final _kpiController = TextEditingController();
  final _prestasiController = TextEditingController();
  final _materiController = TextEditingController();

  String _status = 'Aktif';
  Uint8List? _imageBytes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _namaController.text = widget.initialData!['nama'] ?? '';
      _jabatanController.text = widget.initialData!['jabatan'] ?? '';
      _kpiController.text = (widget.initialData!['KPI'] ?? '').toString();
      _prestasiController.text = widget.initialData!['prestasi'] ?? '';
      _materiController.text = widget.initialData!['materi_pembelajaran'] ?? '';
      _status = widget.initialData!['status'] ?? 'Aktif';
    }
  }

  Future<void> _pickImage() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;
    final file = input.files?.first;
    if (file != null) {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      setState(() => _imageBytes = reader.result as Uint8List);
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final pegawaiData = {
        'nama': _namaController.text.trim(),
        'jabatan': _jabatanController.text.trim(),
        'status': _status,
        'KPI': int.tryParse(_kpiController.text) ?? 0,
        'prestasi': _prestasiController.text.trim(),
        'materi_pembelajaran': _materiController.text.trim(),
        'unit_kerja': widget.unitKerja,
        'foto_url': null,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (widget.docId == null) {
        // Tambah pegawai baru
        await FirebaseFirestore.instance.collection('pegawai').add({
          ...pegawaiData,
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        // Edit data pegawai
        await FirebaseFirestore.instance
            .collection('pegawai')
            .doc(widget.docId)
            .update(pegawaiData);
      }

      if (mounted) {
        Navigator.pop(context); // ✅ Tutup form otomatis
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.docId == null
                ? '✅ Pegawai berhasil ditambahkan'
                : '✅ Data pegawai diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal menyimpan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        widget.docId == null
            ? 'Tambah Pegawai ${widget.unitKerja}'
            : 'Edit Pegawai ${widget.unitKerja}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                    child: _imageBytes == null
                        ? const Icon(Icons.camera_alt, size: 30)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _namaController,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                ),
                TextFormField(
                  controller: _jabatanController,
                  decoration: const InputDecoration(labelText: 'Jabatan'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Jabatan wajib diisi' : null,
                ),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                    DropdownMenuItem(value: 'Nonaktif', child: Text('Nonaktif')),
                  ],
                  onChanged: _saving ? null : (v) => setState(() => _status = v!),
                ),
                TextFormField(
                  controller: _kpiController,
                  decoration: const InputDecoration(labelText: 'KPI'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _prestasiController,
                  decoration: const InputDecoration(labelText: 'Prestasi'),
                ),
                TextFormField(
                  controller: _materiController,
                  decoration: const InputDecoration(labelText: 'Materi/Cara Kerja'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _saveData,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
