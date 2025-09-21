class UserModel {
  final String id;
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
      id: json["_id"]?.toString() ?? "",  // MongoDB ObjectId as String
      username: json['username'] ?? 'Unknown',
      email: json['email'],
    );
  }

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
    };
  }
}
