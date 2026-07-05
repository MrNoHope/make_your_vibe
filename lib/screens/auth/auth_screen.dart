import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/auth_widgets.dart';

enum AuthMode {
  login,
  register,
  forgot,
}

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthScreen({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthMode mode = AuthMode.login;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void submit() {
    FocusScope.of(context).unfocus();
    widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = mode == AuthMode.login;
    final isRegister = mode == AuthMode.register;
    final isForgot = mode == AuthMode.forgot;

    final title = isLogin
        ? 'Đăng nhập'
        : isRegister
        ? 'Đăng ký tài khoản'
        : 'Quên mật khẩu';

    final button = isLogin
        ? 'Đăng nhập'
        : isRegister
        ? 'Đăng ký'
        : 'Gửi mã khôi phục';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
          children: [
            const SizedBox(height: 8),
            Center(
              child: Column(
                children: [
                  const AppLogo(size: 56),
                  const SizedBox(height: 12),
                  Text(
                    'Make Your Vibe',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 34),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            AuthHint(
              text: isForgot
                  ? 'Nhập email để khôi phục tài khoản.'
                  : 'Kết nối âm nhạc và vibe cá nhân của bạn.',
            ),
            const SizedBox(height: 28),
            if (isRegister) ...[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Tên hiển thị',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Email',
                prefixIcon: Icon(Icons.mail_rounded),
              ),
            ),
            if (!isForgot) ...[
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Mật khẩu',
                  prefixIcon: Icon(Icons.lock_rounded),
                  suffixIcon: Icon(Icons.visibility_off_rounded),
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: submit,
              child: Text(button),
            ),
            const SizedBox(height: 14),
            if (isLogin)
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      mode = AuthMode.forgot;
                    });
                  },
                  child: const Text('Quên mật khẩu?'),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  mode = isRegister ? AuthMode.login : AuthMode.register;
                });
              },
              child: Text(
                isRegister ? 'Đã có tài khoản? Đăng nhập' : 'Tạo tài khoản mới',
              ),
            ),
            if (isForgot) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    mode = AuthMode.login;
                  });
                },
                child: const Text('Quay lại đăng nhập'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}