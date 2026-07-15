import 'package:flutter/material.dart';

import '../../app_dependencies.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.c});

  final AppController c;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool registerMode = false;
  bool hidePassword = true;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.background2],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  children: [
                    const AppLogo(size: 92),
                    const SizedBox(height: 24),
                    const Text(
                      'Make Your Vibe',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.tr(
                        'Nghe nhạc, phối không gian và tạo chất riêng.',
                        'Listen, mix ambience, and make your vibe.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.soft),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.panel.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        children: [
                          Text(
                            registerMode
                                ? c.tr('Tạo tài khoản', 'Create account')
                                : c.tr('Đăng nhập', 'Sign in'),
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (registerMode) ...[
                            TextField(
                              controller: nameController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: c.tr('Tên hiển thị', 'Display name'),
                                prefixIcon: const Icon(Icons.person_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_rounded),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: passwordController,
                            obscureText: hidePassword,
                            onSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: c.tr('Mật khẩu', 'Password'),
                              prefixIcon: const Icon(Icons.lock_rounded),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => hidePassword = !hidePassword,
                                ),
                                icon: Icon(
                                  hidePassword
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                ),
                              ),
                            ),
                          ),
                          if (c.error.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              c.error,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _submit,
                              child: Text(
                                registerMode
                                    ? c.tr('Tạo tài khoản', 'Create account')
                                    : c.tr('Đăng nhập', 'Sign in'),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(
                              () => registerMode = !registerMode,
                            ),
                            child: Text(
                              registerMode
                                  ? c.tr(
                                      'Đã có tài khoản? Đăng nhập',
                                      'Already registered? Sign in',
                                    )
                                  : c.tr(
                                      'Chưa có tài khoản? Đăng ký',
                                      'New here? Register',
                                    ),
                            ),
                          ),
                          const Divider(height: 28),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final vertical = constraints.maxWidth < 330;
                              final google = OutlinedButton.icon(
                                onPressed: () => c.social('google'),
                                icon: const Icon(Icons.g_mobiledata_rounded),
                                label: const Text('Google Demo'),
                              );
                              final facebook = OutlinedButton.icon(
                                onPressed: () => c.social('facebook'),
                                icon: const Icon(Icons.facebook_rounded),
                                label: const Text('Facebook Demo'),
                              );
                              if (vertical) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    google,
                                    const SizedBox(height: 10),
                                    facebook,
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(child: google),
                                  const SizedBox(width: 10),
                                  Expanded(child: facebook),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (registerMode) {
      await widget.c.register(
        nameController.text,
        emailController.text,
        passwordController.text,
      );
    } else {
      await widget.c.login(emailController.text, passwordController.text);
    }
  }
}
