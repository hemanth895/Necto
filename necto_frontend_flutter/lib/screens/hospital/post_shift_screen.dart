import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/web_layout.dart';

class PostShiftScreen extends StatefulWidget {
  const PostShiftScreen({super.key});

  @override
  State<PostShiftScreen> createState() => _PostShiftScreenState();
}

class _PostShiftScreenState extends State<PostShiftScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _error;
  bool _saving = false;

  final _shiftDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _roleController = TextEditingController();
  String _degreeRequired = '';
  String _streamRequired = '';
  final _latitudeController = TextEditingController(text: '12.9716');
  final _longitudeController = TextEditingController(text: '77.5946');
  final _paymentController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentType = 'per_shift';

  @override
  void dispose() {
    _shiftDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _roleController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _paymentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final payment = double.tryParse(_paymentController.text) ?? 0;
    if (payment <= 0) {
      setState(() => _error = 'Payment amount must be greater than 0');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    final api = context.read<AuthProvider>().apiClient;
    final res = await api.post('/api/hospital/shifts', {
      'shift_date': _shiftDateController.text.trim(),
      'start_time': _startTimeController.text.trim(),
      'end_time': _endTimeController.text.trim(),
      'degree_required': _degreeRequired,
      'stream_required': _streamRequired,
      'role_required': _roleController.text.trim(),
      'latitude': _latitudeController.text.trim(),
      'longitude': _longitudeController.text.trim(),
      'payment_amount': payment,
      'payment_type': _paymentType,
      'notes': _notesController.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.isOk && res.data != null) {
      final id = res.data!['id'];
      if (id != null) context.go('/hospital/shifts/$id/staff');
      else context.go('/hospital');
    } else {
      setState(() => _error = res.error ?? 'Failed to post shift');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Shift'),
        actions: [
          TextButton(onPressed: () => context.go('/hospital'), child: const Text('Home', style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () async { await context.read<AuthProvider>().logout(); if (context.mounted) context.go('/login'); }, child: const Text('Logout', style: TextStyle(color: Colors.white))),
        ],
      ),
      body: WebLayout(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Post Hospital Shift', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
                  ),
                ],
                const SizedBox(height: 24),
                TextFormField(
                  controller: _shiftDateController,
                  decoration: const InputDecoration(labelText: 'Date'),
                  readOnly: true,
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (d != null) _shiftDateController.text = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startTimeController,
                        decoration: const InputDecoration(labelText: 'Start Time'),
                        readOnly: true,
                        onTap: () async {
                          final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                          if (t != null) _startTimeController.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                        },
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _endTimeController,
                        decoration: const InputDecoration(labelText: 'End Time'),
                        readOnly: true,
                        onTap: () async {
                          final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                          if (t != null) _endTimeController.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                        },
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _degreeRequired.isEmpty ? null : _degreeRequired,
                  decoration: const InputDecoration(labelText: 'Required Degree'),
                  items: const ['Diploma', 'BSc', 'MSc', 'BPT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _degreeRequired = v ?? ''),
                  validator: (v) => _degreeRequired.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _streamRequired.isEmpty ? null : _streamRequired,
                  decoration: const InputDecoration(labelText: 'Required Stream'),
                  items: const ['Cardiac Care Technology', 'Nursing', 'Medical Lab Technology', 'Imaging Technology', 'Physiotherapy'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _streamRequired = v ?? ''),
                  validator: (v) => _streamRequired.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _roleController,
                  decoration: const InputDecoration(labelText: 'Required Role'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: TextFormField(controller: _latitudeController, decoration: const InputDecoration(labelText: 'Latitude'), validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
                    const SizedBox(width: 16),
                    Expanded(child: TextFormField(controller: _longitudeController, decoration: const InputDecoration(labelText: 'Longitude'), validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _paymentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Payment Amount (₹)'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null || double.tryParse(v)! <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _paymentType,
                  decoration: const InputDecoration(labelText: 'Payment Type'),
                  items: const [
                    DropdownMenuItem(value: 'per_shift', child: Text('Per Shift')),
                    DropdownMenuItem(value: 'per_hour', child: Text('Per Hour')),
                  ],
                  onChanged: (v) => setState(() => _paymentType = v ?? 'per_shift'),
                ),
                const SizedBox(height: 16),
                TextFormField(controller: _notesController, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes (optional)')),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Post Shift'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
