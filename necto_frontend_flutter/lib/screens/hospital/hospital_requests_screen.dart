import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/web_layout.dart';

class HospitalRequestsScreen extends StatefulWidget {
  const HospitalRequestsScreen({super.key});

  @override
  State<HospitalRequestsScreen> createState() => _HospitalRequestsScreenState();
}

class _HospitalRequestsScreenState extends State<HospitalRequestsScreen> {
  List<dynamic> _requests = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().apiClient;
    final res = await api.get('/api/hospital/requests');
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.isOk && res.data != null) {
        _requests = (res.data!['requests'] as List?) ?? [];
        _error = null;
      } else {
        _error = res.error ?? 'Failed to load requests';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Requests'),
        actions: [
          TextButton(onPressed: () => context.go('/hospital'), child: const Text('Home', style: TextStyle(color: Colors.white))),
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
                    const Text('Requests You Sent', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
                      ),
                    ],
                    if (_requests.isEmpty && _error == null)
                      const Padding(padding: EdgeInsets.only(top: 24), child: Text('No requests yet. Send a request from a shift\'s available staff.')),
                    if (_requests.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      ..._requests.map((r) {
                        final status = r['status'] ?? '—';
                        final staffName = r['staff_name'] ?? '—';
                        final shiftDate = r['shift_date'] ?? '—';
                        final startTime = r['start_time'] ?? '—';
                        final endTime = r['end_time'] ?? '—';
                        final role = r['role_required'] ?? '—';
                        final payment = r['payment_amount'];
                        final dist = r['distance_km'];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(staffName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: status == 'pending'
                                            ? Colors.amber.shade100
                                            : status == 'accepted'
                                                ? Colors.green.shade100
                                                : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(status, style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('$shiftDate · $startTime – $endTime'),
                                Text('Role: $role'),
                                if (payment != null) Text('Payment: ₹${payment.toStringAsFixed(0)}'),
                                if (dist != null) Text('Distance: ${dist.toStringAsFixed(1)} km'),
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
