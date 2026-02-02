import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/web_layout.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _staffCount = 0;
  int _hospitalCount = 0;
  int _pendingStaff = 0;
  int _pendingHospital = 0;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().apiClient;
    final res = await api.get('/api/admin/dashboard');
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.isOk && res.data != null) {
        _staffCount = (res.data!['staff_count'] as num?)?.toInt() ?? 0;
        _hospitalCount = (res.data!['hospital_count'] as num?)?.toInt() ?? 0;
        _pendingStaff = (res.data!['pending_staff'] as num?)?.toInt() ?? 0;
        _pendingHospital = (res.data!['pending_hospital'] as num?)?.toInt() ?? 0;
      } else {
        _error = res.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Necto Admin'),
        actions: [
          TextButton(onPressed: () => context.go('/admin'), child: const Text('Dashboard', style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () => context.go('/admin/staff'), child: const Text('Verify Staff', style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () => context.go('/admin/hospitals'), child: const Text('Verify Hospitals', style: TextStyle(color: Colors.white))),
          TextButton(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : WebLayout(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Admin Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Welcome, Admin. Manage verification and monitor platform activity.'),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _statCard('Total Staff', _staffCount.toString(), Colors.blue.shade50),
                        _statCard('Total Hospitals', _hospitalCount.toString(), Colors.green.shade50),
                        _statCard('Pending Staff Verification', _pendingStaff.toString(), Colors.orange.shade50),
                        _statCard('Pending Hospital Verification', _pendingHospital.toString(), Colors.red.shade50),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => context.go('/admin/staff'),
                          child: const Text('Review Staff →'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () => context.go('/admin/hospitals'),
                          child: const Text('Review Hospitals →'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(String title, String value, Color bg) {
    return SizedBox(
      width: 220,
      child: Card(
        color: bg,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
