import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/excel_export.dart';
import 'package:fl_chart/fl_chart.dart';

class YayasanDashboard extends StatefulWidget {
  const YayasanDashboard({super.key});

  @override
  State<YayasanDashboard> createState() => _YayasanDashboardState();
}

class _YayasanDashboardState extends State<YayasanDashboard> {
  String? _selectedUnit; // Filter unit kerja
  final List<String> _unitOptions = [
    'Semua Unit',
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
    final pegawaiStream = (_selectedUnit == null || _selectedUnit == 'Semua Unit')
        ? FirebaseFirestore.instance.collection('pegawai').snapshots()
        : FirebaseFirestore.instance
            .collection('pegawai')
            .where('unit_kerja', isEqualTo: _selectedUnit)
            .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Dashboard Yayasan YPBIC'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          const IconButton(
            tooltip: 'Ekspor ke Excel',
            icon: Icon(Icons.file_download),
            onPressed: exportPegawaiToExcel,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: pegawaiStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('❌ Terjadi kesalahan: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text('Belum ada data pegawai yang ditambahkan.'),
            );
          }

          // Hitung statistik
          final total = docs.length;
          final aktif = docs.where((e) => e['status'] == 'Aktif').length;
          final nonaktif = docs.where((e) => e['status'] == 'Nonaktif').length;

          // Hitung per unit & KPI rata-rata
          final unitStats = <String, List<int>>{};
          for (var d in docs) {
            final unit = (d['unit_kerja'] ?? 'Lainnya').toString();
            final kpi = int.tryParse(d['KPI']?.toString() ?? '0') ?? 0;
            unitStats.putIfAbsent(unit, () => []).add(kpi);
          }

          final avgKpiPerUnit = {
            for (var e in unitStats.entries)
              e.key: e.value.isNotEmpty
                  ? e.value.reduce((a, b) => a + b) / e.value.length
                  : 0.0
          };

          // Pie Chart distribusi
          final pieSections = unitStats.entries.map((e) {
            final index = unitStats.keys.toList().indexOf(e.key);
            return PieChartSectionData(
              title: e.key,
              value: e.value.length.toDouble(),
              color: Colors.primaries[index % Colors.primaries.length],
              radius: 60,
              titleStyle: const TextStyle(fontSize: 11, color: Colors.white),
            );
          }).toList();

          // Bar Chart KPI
          final barGroups = avgKpiPerUnit.entries.map((e) {
            final idx = avgKpiPerUnit.keys.toList().indexOf(e.key);
            return BarChartGroupData(
              x: idx,
              barRods: [
                BarChartRodData(
                  toY: e.value,
                  color:
                      Colors.primaries[idx % Colors.primaries.length].shade400,
                  width: 24,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: [
                // Header + Dropdown Filter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Selamat Datang, Yayasan 👋',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: _selectedUnit ?? 'Semua Unit',
                      items: _unitOptions.map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedUnit = value);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Statistik Cards
                Row(
                  children: [
                    _statCard('Total Pegawai', total, Icons.people),
                    _statCard('Aktif', aktif, Icons.check_circle_outline),
                    _statCard('Nonaktif', nonaktif, Icons.cancel_outlined),
                  ],
                ),

                const SizedBox(height: 40),

                // Pie Chart
                Text(
                  '📊 Distribusi Pegawai ${_selectedUnit == null || _selectedUnit == "Semua Unit" ? "per Unit" : "($_selectedUnit)"}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: pieSections,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Bar Chart KPI Rata-rata
                const Text(
                  '📈 Rata-Rata KPI Pegawai per Unit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 250,
                      child: BarChart(
                        BarChartData(
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, _) {
                                  final index = value.toInt();
                                  if (index >= avgKpiPerUnit.keys.length) {
                                    return const SizedBox();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      avgKpiPerUnit.keys.elementAt(index),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: barGroups,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Data Pegawai Table
                const Text(
                  '📋 Data Pegawai Lengkap',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Nama')),
                        DataColumn(label: Text('Unit')),
                        DataColumn(label: Text('Jabatan')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('KPI')),
                        DataColumn(label: Text('Prestasi')),
                      ],
                      rows: docs.map((d) {
                        final m = d.data() as Map<String, dynamic>;
                        return DataRow(cells: [
                          DataCell(Text(m['nama'] ?? '-')),
                          DataCell(Text(m['unit_kerja'] ?? '-')),
                          DataCell(Text(m['jabatan'] ?? '-')),
                          DataCell(Text(m['status'] ?? '-')),
                          DataCell(Text('${m['KPI'] ?? '-'}')),
                          DataCell(Text(m['prestasi'] ?? '-')),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String title, int value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.only(right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue.shade700, size: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text('$value',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
