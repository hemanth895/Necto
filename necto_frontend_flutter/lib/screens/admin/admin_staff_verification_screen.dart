import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/web_layout.dart';

class AdminStaffVerificationScreen extends StatefulWidget {
  const AdminStaffVerificationScreen({super.key});

  @override
  State<AdminStaffVerificationScreen> createState() => _AdminStaffVerificationScreenState();
}

class _AdminStaffVerificationScreenState extends State<AdminStaffVerificationScreen> {
  List<dynamic> _staff = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().apiClient;
    final res = await api.get('/api/admin/staff/pending');
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.isOk && res.data != null) {
        _staff = (res.data!['staff'] as List?) ?? [];
      } else {
        _error = res.error;
      }
    });
  }

  Future<void> _verify(int profileId, bool approve, [String? rejectionReason]) async {
    final api = context.read<AuthProvider>().apiClient;
    final res = await api.post('/api/admin/staff/$profileId/verify', {
      'approve': approve,
      'rejection_reason': rejectionReason ?? '',
    });
    if (!mounted) return;
    if (res.isOk) {
      _load();
    } else {
      setState(() => _error = res.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Staff'),
        actions: [
          TextButton(onPressed: () => context.go('/admin'), child: const Text('Dashboard', style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () async { await context.read<AuthProvider>().logout(); if (context.mounted) context.go('/login'); }, child: const Text('Logout', style: TextStyle(color: Colors.white))),
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
                    const Text('Pending Staff Verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
                      ),
                    ],
                    if (_staff.isEmpty) ...[
                      const SizedBox(height: 24),
                      const Text('No staff pending verification.'),
                    ],
                    if (_staff.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      ..._staff.map((e) {
                        final id = e['ProfileID'] ?? e['profile_id'] ?? e['id'];
                        final name = e['FullName'] ?? e['full_name'] ?? '—';
                        final email = e['Email'] ?? e['email'] ?? '—';
                        final degree = e['Degree'] ?? e['degree'] ?? '—';
                        final stream = e['Stream'] ?? e['stream'] ?? '—';
                        final exp = e['ExperienceYears'] ?? e['experience_years'] ?? '—';
                        final institution = e['CurrentInstitution'] ?? e['current_institution'] ?? '—';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Row(
                                      children: [
                                        TextButton(
                                          onPressed: () => _verify(id, true),
                                          child: const Text('Approve'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            final c = TextEditingController();
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Reject – Reason'),
                                                content: TextField(
                                                  controller: c,
                                                  decoration: const InputDecoration(labelText: 'Rejection reason'),
                                                  maxLines: 2,
                                                ),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(ctx);
                                                      _verify(id, false, c.text.trim());
                                                    },
                                                    child: const Text('Reject'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          child: const Text('Reject'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Email: $email'),
                                Text('$degree – $stream'),
                                Text('Experience: $exp years'),
                                Text('Institution: $institution'),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
