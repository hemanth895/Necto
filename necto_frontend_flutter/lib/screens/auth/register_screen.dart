import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/web_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'hospital';
  bool _agreeTerms = false;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_agreeTerms) {
      setState(() => _error = 'You must agree to Terms & Privacy Policy');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    final auth = context.read<AuthProvider>();
    final err = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _role,
      agreeTerms: _agreeTerms,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F766E), Color(0xFF0891B2)],
          ),
        ),
        child: Center(
          child: WebLayout(
            maxWidth: 420,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextButton(
                          onPressed: () => context.go('/'),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_back, size: 18), SizedBox(width: 4), Text('Back')]),
                        ),
                        const SizedBox(height: 8),
                        const Text('Create Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Text(_error!, style: TextStyle(color: Colors.amber.shade900)),
                          ),
                        ],
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Full Name'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email Address'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Email is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Create Password'),
                          validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
                        ),
                        const SizedBox(height: 16),
                        const Text('Account type', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Radio<String>(value: 'hospital', groupValue: _role, onChanged: (v) => setState(() => _role = v!)),
                            const Text('Hospital'),
                            const SizedBox(width: 16),
                            Radio<String>(value: 'staff', groupValue: _role, onChanged: (v) => setState(() => _role = v!)),
                            const Text('Paramedical Staff'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          value: _agreeTerms,
                          onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                          title: const Text('I agree to Terms & Conditions and Privacy Policy'),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loading ? null : () async {
                            if (_formKey.currentState?.validate() ?? false) await _submit();
                          },
                          child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Register'),
                        ),
                        const SizedBox(height: 16),
                        const Center(child: Text('Already have an account?')),
                        const SizedBox(height: 4),
                        Center(child: TextButton(onPressed: () => context.go('/login'), child: const Text('Login'))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
