import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/web_layout.dart';

class HospitalProfileScreen extends StatefulWidget {
  const HospitalProfileScreen({super.key});

  @override
  State<HospitalProfileScreen> createState() => _HospitalProfileScreenState();
}

class _HospitalProfileScreenState extends State<HospitalProfileScreen> {
  bool _hasProfile = false;
  String _hospitalName = '';
  String _verified = 'no';
  String? _error;
  bool _loading = true;
  bool _saving = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _contactController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _consent = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _telephoneController.dispose();
    _contactController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().apiClient;
    final res = await api.get('/api/hospital/profile');
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.isOk && res.data != null) {
        _hasProfile = res.data!['has_profile'] == true;
        _hospitalName = (res.data!['hospital_name'] as String?) ?? '';
        _verified = (res.data!['verified'] as String?) ?? 'no';
      }
    });
  }

  Future<void> _submit() async {
    if (!_consent) {
      setState(() => _error = 'You must agree to Terms & Privacy Policy');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _error = null;
      _saving = true;
    });
    final api = context.read<AuthProvider>().apiClient;
    final res = await api.post('/api/hospital/profile', {
      'hospital_name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'telephone': _telephoneController.text.trim(),
      'contact_number': _contactController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'hospital_image': '', // Backend accepts optional; for web we skip image or add file upload later
      'consent': _consent,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.isOk) {
      _load();
    } else {
      setState(() => _error = res.error ?? 'Failed to save');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Necto – Hospital'),
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
                    if (_hasProfile) ...[
                      Text(_hospitalName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (_verified == 'pending')
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
                          child: const Text('Verification Pending. Your hospital profile has been submitted and is under admin review.'),
                        )
                      else if (_verified == 'yes')
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                          child: const Text('Verified. Your hospital profile is verified.'),
                        ),
                    ] else ...[
                      const Text('Create Hospital Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('All fields are mandatory. Profile can be created only once.'),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(labelText: 'Hospital / Clinic Name'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              maxLines: 2,
                              decoration: const InputDecoration(labelText: 'Full Address'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _telephoneController,
                              decoration: const InputDecoration(labelText: 'Telephone Number'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _contactController,
                              decoration: const InputDecoration(labelText: 'Contact Mobile Number'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _pincodeController,
                              decoration: const InputDecoration(labelText: 'Pincode'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            CheckboxListTile(
                              value: _consent,
                              onChanged: (v) => setState(() => _consent = v ?? false),
                              title: const Text('I agree to the Terms & Conditions and Privacy Policy of Necto.'),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _saving ? null : _submit,
                              child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Hospital Profile'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
