import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/web_layout.dart';

class HospitalBookedShiftsScreen extends StatefulWidget {
  const HospitalBookedShiftsScreen({super.key});

  @override
  State<HospitalBookedShiftsScreen> createState() => _HospitalBookedShiftsScreenState();
}

class _HospitalBookedShiftsScreenState extends State<HospitalBookedShiftsScreen> {
  List<dynamic> _booked = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().apiClient;
    final res = await api.get('/api/hospital/booked-shifts');
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.isOk && res.data != null) {
        _booked = (res.data!['booked_shifts'] as List?) ?? [];
        _error = null;
      } else {
        _error = res.error ?? 'Failed to load';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booked Shifts'),
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
                    const Text('Booked Shifts (Contact Revealed)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
                      ),
                    ],
                    if (_booked.isEmpty && _error == null)
                      const Padding(padding: EdgeInsets.only(top: 24), child: Text('No booked shifts yet. When staff accept your request, they will appear here with contact details.')),
                    if (_booked.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      ..._booked.map((b) {
                        final staffName = b['staff_name'] ?? '—';
                        final shiftDate = b['shift_date'] ?? '—';
                        final startTime = b['start_time'] ?? '—';
                        final endTime = b['end_time'] ?? '—';
                        final role = b['role_required'] ?? '—';
                        final payment = b['payment_amount'];
                        final mobile = b['staff_mobile'] ?? '—';
                        final email = b['staff_email'] ?? '—';
                        final address = b['staff_address'] ?? '—';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(staffName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('$shiftDate · $startTime – $endTime · $role'),
                                if (payment != null) Text('Payment: ₹${payment.toStringAsFixed(0)}'),
                                const Divider(),
                                const Text('Contact (revealed after acceptance)', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Mobile: $mobile'),
                                Text('Email: $email'),
                                Text('Address: $address'),
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
