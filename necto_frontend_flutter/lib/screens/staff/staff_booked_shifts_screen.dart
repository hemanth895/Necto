import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/web_layout.dart';

class StaffBookedShiftsScreen extends StatefulWidget {
  const StaffBookedShiftsScreen({super.key});

  @override
  State<StaffBookedShiftsScreen> createState() => _StaffBookedShiftsScreenState();
}

class _StaffBookedShiftsScreenState extends State<StaffBookedShiftsScreen> {
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
    final res = await api.get('/api/staff/booked-shifts');
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
          TextButton(onPressed: () => context.go('/staff'), child: const Text('Home', style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () => context.go('/staff/requests'), child: const Text('Requests', style: TextStyle(color: Colors.white))),
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
                    const Text('Your Booked Shifts (Hospital Contact)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
                      ),
                    ],
                    if (_booked.isEmpty && _error == null)
                      const Padding(padding: EdgeInsets.only(top: 24), child: Text('No booked shifts yet. When you accept a request, it will appear here with hospital contact.')),
                    if (_booked.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      ..._booked.map((b) {
                        final hospitalName = b['hospital_name'] ?? '—';
                        final shiftDate = b['shift_date'] ?? '—';
                        final startTime = b['start_time'] ?? '—';
                        final endTime = b['end_time'] ?? '—';
                        final role = b['role_required'] ?? '—';
                        final payment = b['payment_amount'];
                        final tel = b['hospital_telephone'] ?? '—';
                        final contact = b['hospital_contact'] ?? '—';
                        final address = b['address'] ?? '—';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(hospitalName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('$shiftDate · $startTime – $endTime · $role'),
                                if (payment != null) Text('Payment: ₹${payment.toStringAsFixed(0)}'),
                                const Divider(),
                                const Text('Hospital contact', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Tel: $tel'),
                                Text('Contact: $contact'),
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
