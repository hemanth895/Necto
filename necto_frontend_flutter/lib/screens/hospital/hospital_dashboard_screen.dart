import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/web_layout.dart';

class HospitalDashboardScreen extends StatefulWidget {
  const HospitalDashboardScreen({super.key});

  @override
  State<HospitalDashboardScreen> createState() => _HospitalDashboardScreenState();
}

class _HospitalDashboardScreenState extends State<HospitalDashboardScreen> {
  bool _hasProfile = false;
  bool _verified = false;
  String _hospitalName = '';
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().apiClient;
    final res = await api.get('/api/hospital/dashboard');
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.isOk && res.data != null) {
        _hasProfile = res.data!['has_profile'] == true;
        _hospitalName = (res.data!['hospital_name'] as String?) ?? '';
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
          TextButton(onPressed: () => context.go('/hospital'), child: const Text('Home', style: TextStyle(color: Colors.white))),
          if (_hasProfile) ...[
            TextButton(onPressed: () => context.go('/hospital/profile'), child: const Text('Profile', style: TextStyle(color: Colors.white))),
            if (_verified) ...[
              TextButton(onPressed: () => context.go('/hospital/post-shift'), child: const Text('Post Shift', style: TextStyle(color: Colors.white))),
              TextButton(onPressed: () => context.go('/hospital/post-shift'), child: const Text('View Staff', style: TextStyle(color: Colors.white))),
            ],
          ],
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
                      const Text('Welcome to Necto', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Text('To start posting shifts and accessing verified paramedical staff, please create your hospital or clinic profile.'),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/hospital/profile'),
                        child: const Text('Create Hospital Profile'),
                      ),
                    ] else if (!_verified) ...[
                      Text('Hello, $_hospitalName', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Verification Pending', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text('Your hospital profile has been submitted but is not yet verified. Once verified by admin, you can start posting shifts.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: () => context.go('/hospital/profile'),
                        child: const Text('View Verification Status'),
                      ),
                    ] else ...[
                      Text('$_hospitalName Dashboard', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Text('Your hospital is verified. You can now post shifts and view available paramedical staff.'),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => context.go('/hospital/post-shift'),
                            child: const Text('Post a Shift'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              // View staff requires a shift id; we'll list shifts or use latest
                              context.go('/hospital');
                            },
                            child: const Text('View Available Staff'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
