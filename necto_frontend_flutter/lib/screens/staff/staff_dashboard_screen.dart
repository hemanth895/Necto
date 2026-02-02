import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/web_layout.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  bool _hasProfile = false;
  bool _verified = false;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().apiClient;
    final res = await api.get('/api/staff/dashboard');
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.isOk && res.data != null) {
        _hasProfile = res.data!['has_profile'] == true;
        _verified = res.data!['verified'] == 'yes';
      } else {
        _error = res.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Necto'),
        actions: [
          TextButton(onPressed: () => context.go('/staff'), child: const Text('Home', style: TextStyle(color: Colors.white))),
          if (_hasProfile && _verified)
            TextButton(onPressed: () => context.go('/staff/availability'), child: const Text('Post Availability', style: TextStyle(color: Colors.white))),
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
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                        child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (!_hasProfile) ...[
                      const Text('Complete Your Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Text('You must create your staff profile before proceeding.'),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/staff/profile'),
                        child: const Text('Create Profile'),
                      ),
                    ] else if (!_verified) ...[
                      const Text('Verification Pending', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
                        child: const Text('Your profile has been submitted and is awaiting admin verification. Once verified, you can post your availability.'),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                        child: const Text('Verification completed! You can now post your availability for hospitals.'),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/staff/availability'),
                        child: const Text('Post Availability'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
