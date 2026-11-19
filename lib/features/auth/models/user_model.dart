/// Employee user profile returned by the login API.
class UserModel {
  const UserModel({
    required this.id,
    required this.empCode,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.designation,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      empCode: json['emp_code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  final String id;
  final String empCode;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String designation;
  final String status;

  Map<String, dynamic> toJson() => {
    'id': id,
    'emp_code': empCode,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'designation': designation,
    'status': status,
  };
}

/// Wraps the `data` payload of a successful login response
/// (user profile + auth tokens).
class LoginResult {
  const LoginResult({
    required this.user,
    required this.token,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      expiresIn: json['expires_in'] is int
          ? json['expires_in'] as int
          : int.tryParse(json['expires_in']?.toString() ?? '') ?? 0,
    );
  }

  final UserModel user;
  final String token;
  final String refreshToken;
  final int expiresIn;
}

class RefreshResult {
  const RefreshResult({required this.token, required this.expiresIn});

  factory RefreshResult.fromJson(Map<String, dynamic> json) {
    return RefreshResult(
      token: json['token']?.toString() ?? '',
      expiresIn: json['expires_in'] is int
          ? json['expires_in'] as int
          : int.tryParse(json['expires_in']?.toString() ?? '') ?? 0,
    );
  }

  final String token;
  final int expiresIn;
}
