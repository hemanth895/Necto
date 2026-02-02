import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/web_layout.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFF0F766E),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Necto',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Login', style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => context.go('/register'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                            ),
                            child: const Text('Register'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: WebLayout(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    const Text(
                      'On-demand Paramedical Staffing for Hospitals',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Hire verified paramedical professionals for emergency, short-term, and shift-based hospital staffing.',
                      style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Get Started'),
                    ),
                    const SizedBox(height: 48),
                    _sectionTitle('Who is Necto for?'),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Hospitals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Post staffing requirements and hire trained paramedical professionals on demand.',
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Paramedical Professionals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Find flexible jobs, shifts, and opportunities that match your skills and availability.',
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    _sectionTitle('How Necto Works'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _stepCard('1. Register & Verify', 'Create an account as hospital or professional and get verified.'),
                        const SizedBox(width: 16),
                        _stepCard('2. Connect', 'Hospitals post jobs. Our platform displays staff with matching requirements.'),
                        const SizedBox(width: 16),
                        _stepCard('3. Work', 'Get hired, work flexibly, and grow professionally.'),
                      ],
                    ),
                    const SizedBox(height: 48),
                    Center(
                      child: Column(
                        children: [
                          const Text('Start Hiring or Working Today', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Simple. Fast. Trusted healthcare staffing.'),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: () => context.go('/register'), child: const Text('Join Necto')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: ColoredBox(
              color: Color(0xFF0F766E),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('© 2025 Necto. All rights reserved. • support@necto.in', style: TextStyle(color: Colors.white70)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827)));
  }

  Widget _stepCard(String title, String body) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(body, style: const TextStyle(color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}
