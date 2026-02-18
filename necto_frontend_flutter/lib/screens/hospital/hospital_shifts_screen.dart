import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/web_layout.dart';

class HospitalShiftsScreen extends StatefulWidget {
  const HospitalShiftsScreen({super.key});

  @override
  State<HospitalShiftsScreen> createState() => _HospitalShiftsScreenState();
}

class _HospitalShiftsScreenState extends State<HospitalShiftsScreen> {
  List<dynamic> _shifts = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().apiClient;
    final res = await api.get('/api/hospital/shifts');
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.isOk && res.data != null) {
        _shifts = (res.data!['shifts'] as List?) ?? [];
        _error = null;
      } else {
        _error = res.error ?? 'Failed to load shifts';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shifts'),
        actions: [
          TextButton(onPressed: () => context.go('/hospital'), child: const Text('Home', style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () => context.go('/hospital/post-shift'), child: const Text('Post Shift', style: TextStyle(color: Colors.white))),
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
                    const Text('Your Shifts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
                      ),
                    ],
                    if (_shifts.isEmpty && _error == null)
                      const Padding(padding: EdgeInsets.only(top: 24), child: Text('No shifts yet. Post a shift to get started.')),
                    if (_shifts.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      ..._shifts.map((s) {
                        final id = s['id'];
                        final status = s['status'] ?? '—';
                        final shiftDate = s['shift_date'] ?? '—';
                        final startTime = s['start_time'] ?? '—';
                        final endTime = s['end_time'] ?? '—';
                        final role = s['role_required'] ?? '—';
                        final payment = s['payment_amount'];
                        final isOpen = status == 'open';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('$shiftDate $startTime – $endTime', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text('Role: $role'),
                                      if (payment != null) Text('Payment: ₹${payment.toStringAsFixed(0)}'),
                                      Text('Status: $status', style: TextStyle(color: isOpen ? Colors.green : Colors.grey)),
                                    ],
                                  ),
                                ),
                                if (isOpen && id != null)
                                  ElevatedButton(
                                    onPressed: () => context.push('/hospital/shifts/$id/staff'),
                                    child: const Text('View Available Staff'),
                                  ),
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
