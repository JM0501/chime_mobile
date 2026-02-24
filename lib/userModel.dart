class UserModel {
  final String id;
  final String username;
  final String? email;

  UserModel({
    required this.id,
    required this.username,
    this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["_id"] ?? "",
      username: json["username"] ?? "",
      email: json["email"],
    );
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "username": username,
        "email": email,
      };
}
