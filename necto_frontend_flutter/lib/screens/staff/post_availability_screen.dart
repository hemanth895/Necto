import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/web_layout.dart';

/// Karnataka districts for staff availability (matches backend)
const List<String> karnatakaDistricts = [
  'Bagalkot', 'Ballari', 'Belagavi', 'Bengaluru Rural', 'Bengaluru Urban',
  'Bidar', 'Chamarajanagar', 'Chikkaballapur', 'Chikkamagaluru', 'Chitradurga',
  'Dakshina Kannada', 'Davangere', 'Dharwad', 'Gadag', 'Hassan', 'Haveri',
  'Kalaburagi', 'Kodagu', 'Kolar', 'Koppal', 'Mandya', 'Mysuru', 'Raichur',
  'Ramanagara', 'Shivamogga', 'Tumakuru', 'Udupi', 'Uttara Kannada',
  'Vijayanagara', 'Vijayapura', 'Yadgir',
];

class PostAvailabilityScreen extends StatefulWidget {
  const PostAvailabilityScreen({super.key});

  @override
  State<PostAvailabilityScreen> createState() => _PostAvailabilityScreenState();
}

class _PostAvailabilityScreenState extends State<PostAvailabilityScreen> {
  String? _error;
  bool _saving = false;
  String _district = '';
  final _talukaController = TextEditingController();
  final _workDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _latitudeController = TextEditingController(text: '12.9716');
  final _longitudeController = TextEditingController(text: '77.5946');

  @override
  void dispose() {
    _talukaController.dispose();
    _workDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_district.isEmpty || _talukaController.text.trim().isEmpty) {
      setState(() => _error = 'District and Taluka are required');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    final api = context.read<AuthProvider>().apiClient;
    final res = await api.post('/api/staff/availability', {
      'district': _district,
      'taluka': _talukaController.text.trim(),
      'work_date': _workDateController.text.trim(),
      'start_time': _startTimeController.text.trim(),
      'end_time': _endTimeController.text.trim(),
      'latitude': double.tryParse(_latitudeController.text) ?? 12.9716,
      'longitude': double.tryParse(_longitudeController.text) ?? 77.5946,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.isOk) {
      context.go('/staff');
    } else {
      setState(() => _error = res.error ?? 'Failed to post availability');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Availability'),
        actions: [
          TextButton(onPressed: () => context.go('/staff'), child: const Text('Home', style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () async { await context.read<AuthProvider>().logout(); if (context.mounted) context.go('/login'); }, child: const Text('Logout', style: TextStyle(color: Colors.white))),
        ],
      ),
      body: WebLayout(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Create Availability', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
                ),
              ],
              const SizedBox(height: 24),
              const Text('State: Karnataka'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _district.isEmpty ? null : _district,
                decoration: const InputDecoration(labelText: 'District'),
                items: karnatakaDistricts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _district = v ?? ''),
                validator: (v) => _district.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _talukaController,
                decoration: const InputDecoration(labelText: 'Taluka'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _workDateController,
                decoration: const InputDecoration(labelText: 'Work Date'),
                readOnly: true,
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (d != null) _workDateController.text = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _latitudeController, decoration: const InputDecoration(labelText: 'Latitude'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _longitudeController, decoration: const InputDecoration(labelText: 'Longitude'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Post Availability'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
