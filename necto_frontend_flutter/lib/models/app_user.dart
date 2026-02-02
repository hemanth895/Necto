class AppUser {
  final int id;
  final String email;
  final String role; // 'hospital' | 'staff' | 'admin'
  final String? name;

  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.name,
  });
}
