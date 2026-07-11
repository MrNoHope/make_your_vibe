import 'package:flutter/material.dart';

import '../../services/user_gateway.dart';
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
  bool loading = false;
  String errorMessage = '';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final name = nameController.text.trim();

    if (email.isEmpty || (!isForgotMode && password.isEmpty)) {
      setState(() {
        errorMessage = 'Nhập email và mật khẩu để tiếp tục.';
      });
      return;
    }

    if (isRegisterMode && name.isEmpty) {
      setState(() {
        errorMessage = 'Nhập tên hiển thị để tạo tài khoản.';
      });
      return;
    }

    await _runAuthAction(() async {
      if (isForgotMode) {
        await userGateway.sendPasswordReset(email);
        setState(() {
          mode = AuthMode.login;
          errorMessage = 'Đã gửi email khôi phục mật khẩu.';
        });
        return;
      }

      if (isRegisterMode) {
        await userGateway.register(name, email, password);
      } else {
        await userGateway.login(email, password);
      }

      widget.onAuthenticated();
    });
  }

  bool get isRegisterMode => mode == AuthMode.register;

  bool get isForgotMode => mode == AuthMode.forgot;

  Future<void> signInWithGoogle() async {
    await _runAuthAction(() async {
      await userGateway.signInWithGoogle();
      widget.onAuthenticated();
    });
  }

  Future<void> signInWithFacebook() async {
    await _runAuthAction(() async {
      await userGateway.signInWithFacebook();
      widget.onAuthenticated();
    });
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    setState(() {
      loading = true;
      errorMessage = '';
    });

    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = '$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
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
              onPressed: loading ? null : submit,
              child: Text(button),
            ),
            if (!isForgot) ...[
              const SizedBox(height: 12),
              AuthProviderButton(
                onPressed: loading ? null : signInWithGoogle,
                logo: const GoogleLogo(),
                label: 'Đăng nhập bằng Google',
              ),
              const SizedBox(height: 10),
              AuthProviderButton(
                onPressed: loading ? null : signInWithFacebook,
                logo: const FacebookLogo(),
                label: 'Đăng nhập bằng Facebook',
              ),
            ],
            if (errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: errorMessage.startsWith('Đã gửi')
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
