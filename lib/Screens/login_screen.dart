import 'package:flutter/material.dart';
import 'package:trial_app/Screens/register_screen.dart';
import 'package:trial_app/Controllers/auth_controller.dart';
import 'package:trial_app/Screens/home_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trial_app/theme/app_theme.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _auth = AuthController();
  bool _loading = false;

  void _login() async {
    final email = _email.text.trim();
    final pass = _pass.text;
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email dan password wajib diisi')));
      return;
    }
    setState(() => _loading = true);
    final res = await _auth.loginWithMessage(email, pass);
    if (mounted) setState(() => _loading = false);
    if (res.user != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(user: res.user!)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Login gagal')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: AppTheme.navyDark,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Gambar header
              Container(
                width: double.infinity,
                height: 200,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: const BoxDecoration(
                  color: AppTheme.navyDark,
                ),
                child: SvgPicture.asset(
                  'image/2.svg',
                  fit: BoxFit.contain,
                  placeholderBuilder: (context) => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.green),
                    ),
                  ),
                ),
              ),
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pass,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text('Belum punya akun? Register'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
