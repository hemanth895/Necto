import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/web_layout.dart';

class ViewAvailableStaffScreen extends StatefulWidget {
  const ViewAvailableStaffScreen({super.key, required this.shiftId});

  final String shiftId;

  @override
  State<ViewAvailableStaffScreen> createState() => _ViewAvailableStaffScreenState();
}

class _ViewAvailableStaffScreenState extends State<ViewAvailableStaffScreen> {
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
    final res = await api.get('/api/hospital/shifts/${widget.shiftId}/available-staff');
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.isOk && res.data != null) {
        _staff = (res.data!['staff'] as List?) ?? [];
        _error = _staff.isEmpty ? 'No available staff for this shift.' : null;
      } else {
        _error = res.error ?? 'Failed to load staff';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Staff'),
        actions: [
          TextButton(onPressed: () => context.go('/hospital'), child: const Text('Home', style: TextStyle(color: Colors.white))),
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
                    const Text('Available Staff for Shift', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(_error!, style: TextStyle(color: Colors.orange.shade800)),
                      ),
                    ],
                    if (_staff.isEmpty && _error == null)
                      const Padding(padding: EdgeInsets.only(top: 24), child: Text('No staff available for this shift.')),
                    if (_staff.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      ..._staff.map((e) {
                        final name = e['full_name'] ?? e['name'] ?? '—';
                        final degree = e['degree'] ?? '—';
                        final stream = e['specialization'] ?? e['stream'] ?? '—';
                        final exp = e['experience_years'] ?? '—';
                        final institution = e['current_institution'] ?? '—';
                        final role = e['working_role'] ?? '—';
                        final distance = e['distance'];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('$degree – $stream'),
                                Text('Experience: $exp years'),
                                Text('Institution: $institution'),
                                Text('Role: $role'),
                                if (distance != null) Text('Distance: ${distance.toStringAsFixed(1)} km'),
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
