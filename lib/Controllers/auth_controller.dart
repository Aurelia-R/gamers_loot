import 'package:bcrypt/bcrypt.dart';
import 'package:uuid/uuid.dart';
import 'package:trial_app/Services/supabase_service.dart';
import 'package:trial_app/Models/user_model.dart';
import 'package:trial_app/Services/session_service.dart';

class LoginResponse {
  final UserModel? user;
  final String? error;
  LoginResponse({this.user, this.error});
}

class AuthController {
  final _svc = SupabaseService();
  final _session = SessionService();

  Future<String?> register(String uname, String email, String pass) async {
    final id = const Uuid().v4();
    final hashed = BCrypt.hashpw(pass, BCrypt.gensalt());
    final user = UserModel(
      id: id,
      username: uname,
      email: email,
      passwordHash: hashed,
    );
    final res = await _svc.registerUser(user);
    return res ? "Register success" : null;
  }

  Future<UserModel?> login(String email, String pass) async {
    final data = await _svc.getUserByEmail(email);
    if (data == null) return null;
    final hash = data['password'];
    if (BCrypt.checkpw(pass, hash)) {
      final user = UserModel(
        id: data['id'],
        username: data['username'],
        email: data['email'],
        passwordHash: data['password'],
        photoUrl: data['photo_url'],
      );
      await _session.saveUser(user);
      return user;
    }
    return null;
  }

  Future<LoginResponse> loginWithMessage(String email, String pass) async {
    final data = await _svc.getUserByEmail(email);
    if (data == null) {
      return LoginResponse(error: 'Email tidak terdaftar atau tidak dapat diakses');
    }
    final hash = data['password'];
    final isMatch = hash is String && BCrypt.checkpw(pass, hash);
    if (!isMatch) {
      return LoginResponse(error: 'Password salah');
    }
    final user = UserModel(
      id: data['id'],
      username: data['username'],
      email: data['email'],
      passwordHash: data['password'],
      photoUrl: data['photo_url'],
    );
    await _session.saveUser(user);
    return LoginResponse(user: user);
  }

  Future<void> logout() async {
    await _session.clear();
  }
}
