import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_hospital_verification_screen.dart';
import 'screens/admin/admin_staff_verification_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/hospital/hospital_dashboard_screen.dart';
import 'screens/hospital/hospital_profile_screen.dart';
import 'screens/hospital/post_shift_screen.dart';
import 'screens/hospital/view_available_staff_screen.dart';
import 'screens/staff/post_availability_screen.dart';
import 'screens/staff/staff_dashboard_screen.dart';
import 'screens/staff/staff_profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(BuildContext context, AuthProvider auth) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();
      if (auth.loading) return null;
      final loggedIn = auth.isLoggedIn;
      final role = auth.role;
      final path = state.uri.path;

      // Public routes
      if (path == '/' || path == '/login' || path == '/register' ||
          path == '/forgot-password' || path.startsWith('/reset-password')) {
        if (loggedIn && role != null) {
          if (role == 'admin') return '/admin';
          if (role == 'hospital') return '/hospital';
          if (role == 'staff') return '/staff';
        }
        return null;
      }

      if (!loggedIn) return '/login';

      if (path.startsWith('/admin') && role != 'admin') return '/';
      if (path.startsWith('/hospital') && role != 'hospital') return '/';
      if (path.startsWith('/staff') && role != 'staff') return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/hospital',
        builder: (context, state) => const HospitalDashboardScreen(),
      ),
      GoRoute(
        path: '/hospital/profile',
        builder: (context, state) => const HospitalProfileScreen(),
      ),
      GoRoute(
        path: '/hospital/post-shift',
        builder: (context, state) => const PostShiftScreen(),
      ),
      GoRoute(
        path: '/hospital/shifts/:id/staff',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ViewAvailableStaffScreen(shiftId: id);
        },
      ),
      GoRoute(
        path: '/staff',
        builder: (context, state) => const StaffDashboardScreen(),
      ),
      GoRoute(
        path: '/staff/profile',
        builder: (context, state) => const StaffProfileScreen(),
      ),
      GoRoute(
        path: '/staff/availability',
        builder: (context, state) => const PostAvailabilityScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/staff',
        builder: (context, state) => const AdminStaffVerificationScreen(),
      ),
      GoRoute(
        path: '/admin/hospitals',
        builder: (context, state) => const AdminHospitalVerificationScreen(),
      ),
    ],
  );
}
