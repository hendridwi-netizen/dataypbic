import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Dashboard sesuai role
import 'admin_dashboard.dart';
import 'yayasan_dashboard.dart';
import 'guru_dashboard.dart';
import 'pimpinan_dashboard.dart';

class RoleChecker extends StatefulWidget {
  const RoleChecker({super.key});

  @override
  State<RoleChecker> createState() => _RoleCheckerState();
}

class _RoleCheckerState extends State<RoleChecker> {
  String? _role;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _role = doc.data()?['role'];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print("Error load role: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    switch (_role) {
      case 'admin':
        return const AdminDashboard();

      case 'yayasan':
        return const YayasanDashboard();

      case 'pegawai':
        return const GuruDashboard();  // 🔥 FIXED

      case 'pimpinan':
        return const PimpinanDashboard(); // 🔥 PENTING

      default:
        return Scaffold(
          body: Center(
            child: Text(
              'Role tidak dikenali atau akun belum diatur: ${_role ?? "null"}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        );
    }
  }
}
