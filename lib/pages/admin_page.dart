import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'unit_kerja_page.dart';
import '../widgets/stat_card.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  static const List<Map<String, dynamic>> unitKerjaList = [
    {'nama': 'TK', 'icon': Icons.school},
    {'nama': 'SD', 'icon': Icons.menu_book},
    {'nama': 'SMP', 'icon': Icons.science},
    {'nama': 'SMA', 'icon': Icons.calculate},
    {'nama': 'Staff/Manajemen', 'icon': Icons.people},
    {'nama': 'Pramubakti', 'icon': Icons.cleaning_services},
    {'nama': 'Maintenance', 'icon': Icons.build},
    {'nama': 'Security', 'icon': Icons.security},
    {'nama': 'Marbot', 'icon': Icons.mosque},
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Dashboard Admin YPBIC'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selamat datang, ${user?.email ?? 'Admin'} 👋',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: const [
                Expanded(child: StatCard(title: 'Total Pegawai', value: '120', icon: Icons.people)),
                SizedBox(width: 16),
                Expanded(child: StatCard(title: 'Pegawai Aktif', value: '115', icon: Icons.verified)),
                SizedBox(width: 16),
                Expanded(child: StatCard(title: 'Nonaktif', value: '5', icon: Icons.warning)),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Unit Kerja', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 4 / 2,
                children: unitKerjaList.map((unit) {
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UnitKerjaPage(unitNama: unit['nama'])),
                    ),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(unit['icon'], size: 40, color: Colors.blue),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(unit['nama'],
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
