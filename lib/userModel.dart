class UserModel {
  final int id;
  final String username;
  final String? email;

  UserModel({
    required this.id,
    required this.username,
    this.email,
  });

  // Factory constructor to create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['Id'] ?? 0,
      username: json['Username'] ?? 'Unknown',
      email: json['Email'],
    );
  }

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Username': username,
      'Email': email,
    };
  }
}
