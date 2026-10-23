class User {
  final String id;
  final String accountId;
  final String name;
  final String email;
  final String phone;
  final String patientCode;
  final String role;
  final String token;

  const User({
    required this.id,
    required this.accountId,
    required this.name,
    required this.email,
    required this.phone,
    required this.patientCode,
    required this.role,
    required this.token,
  });
}
