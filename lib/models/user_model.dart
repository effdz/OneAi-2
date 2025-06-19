class UserModel {
  final String id;
  final String username;
  final String email;
  final DateTime? lastLogin;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.lastLogin,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['user_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'last_login': lastLogin?.toIso8601String(),
      'avatar_url': avatarUrl,
    };
  }
}
