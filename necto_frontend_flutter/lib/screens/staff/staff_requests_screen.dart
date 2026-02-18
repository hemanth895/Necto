import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/web_layout.dart';

class StaffRequestsScreen extends StatefulWidget {
  const StaffRequestsScreen({super.key});

  @override
  State<StaffRequestsScreen> createState() => _StaffRequestsScreenState();
}

class _StaffRequestsScreenState extends State<StaffRequestsScreen> {
  List<dynamic> _requests = [];
  String? _error;
  bool _loading = true;
  int? _respondingTo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().apiClient;
    final res = await api.get('/api/staff/requests');
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

  Future<void> _accept(int requestId) async {
    setState(() {
      _error = null;
      _respondingTo = requestId;
    });
    final api = context.read<AuthProvider>().apiClient;
    final res = await api.post('/api/staff/requests/$requestId/accept', null);
    if (!mounted) return;
    setState(() {
      _respondingTo = null;
      if (res.isOk) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request accepted. Contact is now visible in Booked Shifts.')));
        _load();
      } else {
        _error = res.error ?? 'Failed to accept';
      }
    });
  }

  Future<void> _reject(int requestId, [String? reason]) async {
    setState(() {
      _error = null;
      _respondingTo = requestId;
    });
    final api = context.read<AuthProvider>().apiClient;
    final res = await api.post('/api/staff/requests/$requestId/reject', {'rejection_reason': reason ?? 'Not available'});
    if (!mounted) return;
    setState(() {
      _respondingTo = null;
      if (res.isOk) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected.')));
        _load();
      } else {
        _error = res.error ?? 'Failed to reject';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Requests'),
        actions: [
          TextButton(onPressed: () => context.go('/staff'), child: const Text('Home', style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () => context.go('/staff/booked-shifts'), child: const Text('Booked Shifts', style: TextStyle(color: Colors.white))),
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
                    const Text('Requests from Hospitals', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Contact details are hidden until you accept.', style: TextStyle(color: Colors.grey)),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
                      ),
                    ],
                    if (_requests.isEmpty && _error == null)
                      const Padding(padding: EdgeInsets.only(top: 24), child: Text('No requests yet. When hospitals send you a request, it will appear here.')),
                    if (_requests.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      ..._requests.map((r) {
                        final requestId = r['request_id'];
                        final status = r['status'] ?? '—';
                        final hospitalName = r['hospital_name'] ?? '—';
                        final shiftDate = r['shift_date'] ?? '—';
                        final startTime = r['start_time'] ?? '—';
                        final endTime = r['end_time'] ?? '—';
                        final role = r['role_required'] ?? '—';
                        final payment = r['payment_amount'];
                        final dist = r['distance_km'];
                        final address = r['address'] ?? '—';
                        final pending = status == 'pending';
                        final responding = _respondingTo == requestId;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(hospitalName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: pending ? Colors.amber.shade100 : status == 'accepted' ? Colors.green.shade100 : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('$shiftDate · $startTime – $endTime'),
                                Text('Role: $role'),
                                if (payment != null) Text('Payment: ₹${payment.toStringAsFixed(0)}'),
                                if (dist != null) Text('Distance: ${dist.toStringAsFixed(1)} km'),
                                Text('Location: $address'),
                                if (pending && requestId != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: responding ? null : () => _accept(requestId),
                                        child: responding ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Accept'),
                                      ),
                                      const SizedBox(width: 12),
                                      OutlinedButton(
                                        onPressed: responding ? null : () => _reject(requestId),
                                        child: const Text('Reject'),
                                      ),
                                    ],
                                  ),
                                ],
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
