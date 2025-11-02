class UserModel {
  String id;
  String username;
  String email;
  String passwordHash;
  String? photoUrl;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'password': passwordHash,
        'photo_url': photoUrl,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();
    final username = (json['username'] ?? '').toString();
    final email = (json['email'] ?? '').toString();
    final password = (json['password'] ?? json['password_hash'] ?? '').toString();
    final photoUrl = json['photo_url'] == null ? null : json['photo_url'].toString();

    return UserModel(
      id: id,
      username: username,
      email: email,
      passwordHash: password,
      photoUrl: photoUrl,
    );
  }
}
