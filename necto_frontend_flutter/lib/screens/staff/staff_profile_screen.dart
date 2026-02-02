import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/web_layout.dart';

class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  bool _hasProfile = false;
  String? _error;
  bool _loading = true;
  bool _saving = false;

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _degreeController = TextEditingController();
  final _streamController = TextEditingController();
  final _collegeController = TextEditingController();
  final _experienceController = TextEditingController();
  final _institutionController = TextEditingController();
  final _workingRoleController = TextEditingController();
  final _willingRolesController = TextEditingController();
  final _preferredLocationController = TextEditingController();
  String _consent = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _emergencyController.dispose();
    _degreeController.dispose();
    _streamController.dispose();
    _collegeController.dispose();
    _experienceController.dispose();
    _institutionController.dispose();
    _workingRoleController.dispose();
    _willingRolesController.dispose();
    _preferredLocationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().apiClient;
    final res = await api.get('/api/staff/profile');
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.isOk && res.data != null) {
        _hasProfile = res.data!['has_profile'] == true;
      }
    });
  }

  Future<void> _submit() async {
    if (_consent.isEmpty) {
      setState(() => _error = 'You must agree to consent and privacy policy');
      return;
    }
    if (_mobileController.text.trim() == _emergencyController.text.trim()) {
      setState(() => _error = 'Emergency contact must be different from mobile');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _error = null;
      _saving = true;
    });
    final api = context.read<AuthProvider>().apiClient;
    final res = await api.post('/api/staff/profile', {
      'full_name': _fullNameController.text.trim(),
      'age': int.tryParse(_ageController.text) ?? 0,
      'dob': _dobController.text.trim(),
      'gender': _genderController.text.trim(),
      'address': _addressController.text.trim(),
      'email': _emailController.text.trim(),
      'mobile': _mobileController.text.trim(),
      'emergency_mobile': _emergencyController.text.trim(),
      'degree': _degreeController.text.trim(),
      'stream': _streamController.text.trim(),
      'college': _collegeController.text.trim(),
      'experience_years': int.tryParse(_experienceController.text) ?? 0,
      'current_institution': _institutionController.text.trim(),
      'working_role': _workingRoleController.text.trim(),
      'willing_roles': _willingRolesController.text.trim(),
      'preferred_location': _preferredLocationController.text.trim(),
      'consent': _consent,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.isOk) {
      context.go('/staff');
    } else {
      setState(() => _error = res.error ?? 'Failed to save');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Profile'),
        actions: [
          TextButton(onPressed: () => context.go('/staff'), child: const Text('Home', style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () async { await context.read<AuthProvider>().logout(); if (context.mounted) context.go('/login'); }, child: const Text('Logout', style: TextStyle(color: Colors.white))),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hasProfile
              ? WebLayout(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                      child: const Text('Your profile is under verification. You will be notified once approved.'),
                    ),
                  ),
                )
              : WebLayout(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Staff Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Create profile → Verification → Start working'),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                              child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
                            ),
                          ],
                          const SizedBox(height: 24),
                          TextFormField(controller: _fullNameController, decoration: const InputDecoration(labelText: 'Full Name'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: TextFormField(controller: _ageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age'), validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _dobController,
                                  decoration: const InputDecoration(labelText: 'DOB'),
                                  readOnly: true,
                                  onTap: () async {
                                    final d = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1950), lastDate: DateTime.now());
                                    if (d != null) _dobController.text = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                                  },
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(controller: _genderController, decoration: const InputDecoration(labelText: 'Gender'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                          const SizedBox(height: 16),
                          TextFormField(controller: _addressController, maxLines: 2, decoration: const InputDecoration(labelText: 'Address'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                          const SizedBox(height: 16),
                          TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: TextFormField(controller: _mobileController, decoration: const InputDecoration(labelText: 'Mobile'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
                              const SizedBox(width: 16),
                              Expanded(child: TextFormField(controller: _emergencyController, decoration: const InputDecoration(labelText: 'Emergency Contact'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(controller: _degreeController, decoration: const InputDecoration(labelText: 'Degree'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                          const SizedBox(height: 16),
                          TextFormField(controller: _streamController, decoration: const InputDecoration(labelText: 'Stream / Specialization'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                          const SizedBox(height: 16),
                          TextFormField(controller: _collegeController, decoration: const InputDecoration(labelText: 'College'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: TextFormField(controller: _experienceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Experience (years)'), validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
                              const SizedBox(width: 16),
                              Expanded(child: TextFormField(controller: _institutionController, decoration: const InputDecoration(labelText: 'Current Institution'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(controller: _workingRoleController, decoration: const InputDecoration(labelText: 'Current Role'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                          const SizedBox(height: 16),
                          TextFormField(controller: _willingRolesController, decoration: const InputDecoration(labelText: 'Willing Roles'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                          const SizedBox(height: 16),
                          TextFormField(controller: _preferredLocationController, decoration: const InputDecoration(labelText: 'Preferred Location'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                          const SizedBox(height: 16),
                          CheckboxListTile(
                            value: _consent.isNotEmpty,
                            onChanged: (v) => setState(() => _consent = (v == true) ? 'yes' : ''),
                            title: const Text('I agree to Consent Form & Privacy Policy'),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _saving ? null : _submit,
                            child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Profile'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
