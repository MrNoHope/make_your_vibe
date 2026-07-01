import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/auth_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });

  final Future<bool> Function(String email, String password) onLogin;
  final Future<String?> Function(UserProfile profile, String password) onRegister;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int page = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        child: page == 0
            ? LoginPanel(
                key: const ValueKey('login'),
                onLogin: widget.onLogin,
                onSignUp: () {
                  setState(() {
                    page = 1;
                  });
                },
                onForgot: () {
                  setState(() {
                    page = 2;
                  });
                },
              )
            : page == 1
                ? SignUpPanel(
                    key: const ValueKey('signup'),
                    onRegister: widget.onRegister,
                    onBack: () {
                      setState(() {
                        page = 0;
                      });
                    },
                  )
                : ForgotPanel(
                    key: const ValueKey('forgot'),
                    onBack: () {
                      setState(() {
                        page = 0;
                      });
                    },
                  ),
      ),
    );
  }
}

class LoginPanel extends StatefulWidget {
  const LoginPanel({
    super.key,
    required this.onLogin,
    required this.onSignUp,
    required this.onForgot,
  });

  final Future<bool> Function(String email, String password) onLogin;
  final VoidCallback onSignUp;
  final VoidCallback onForgot;

  @override
  State<LoginPanel> createState() => _LoginPanelState();
}

class _LoginPanelState extends State<LoginPanel> {
  final email = TextEditingController(text: 'umter@st.vibe.app');
  final password = TextEditingController(text: '123456');
  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      loading = true;
    });

    final ok = await widget.onLogin(email.text, password.text);

    if (!mounted) {
      return;
    }

    setState(() {
      loading = false;
    });

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email hoặc mật khẩu không đúng.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Đăng nhập',
      subtitle: 'Make Your Vibe',
      children: [
        const Center(
          child: AppLogo(size: 72),
        ),
        const SizedBox(height: 22),
        AppTextField(
          controller: email,
          hint: 'Email sinh viên',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: password,
          hint: 'Mật khẩu',
          obscure: true,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: widget.onForgot,
            child: const Text('Quên mật khẩu?'),
          ),
        ),
        const SizedBox(height: 8),
        PrimaryButton(
          text: loading ? 'Đang xử lý...' : 'Đăng nhập',
          onPressed: loading ? null : submit,
        ),
        const SizedBox(height: 18),
        const Center(
          child: Text(
            'HOẶC',
            style: TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: widget.onSignUp,
          child: const Text('Chưa có tài khoản? Đăng ký ngay'),
        ),
      ],
    );
  }
}

class SignUpPanel extends StatefulWidget {
  const SignUpPanel({
    super.key,
    required this.onRegister,
    required this.onBack,
  });

  final Future<String?> Function(UserProfile profile, String password) onRegister;
  final VoidCallback onBack;

  @override
  State<SignUpPanel> createState() => _SignUpPanelState();
}

class _SignUpPanelState extends State<SignUpPanel> {
  final name = TextEditingController();
  final studentId = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  bool agree = true;
  bool loading = false;

  @override
  void dispose() {
    name.dispose();
    studentId.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn cần đồng ý với điều khoản dịch vụ.'),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final error = await widget.onRegister(
      UserProfile(
        name: name.text,
        email: email.text,
        studentId: studentId.text,
      ),
      password.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      loading = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Đăng ký tài khoản',
      subtitle: 'Tạo hồ sơ sinh viên của bạn để bắt đầu.',
      children: [
        AppTextField(
          controller: name,
          hint: 'Tên tài khoản',
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: studentId,
          hint: 'Mã số sinh viên',
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: email,
          hint: 'Email sinh viên',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: password,
          hint: 'Mật khẩu',
          obscure: true,
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: agree,
          onChanged: (value) {
            setState(() {
              agree = value ?? false;
            });
          },
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Tôi đồng ý với Điều khoản Dịch vụ và Chính sách Bảo mật.',
            style: TextStyle(fontSize: 13),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 10),
        PrimaryButton(
          text: loading ? 'Đang tạo...' : 'Đăng ký',
          onPressed: loading ? null : submit,
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: widget.onBack,
          child: const Text('Đã có tài khoản? Đăng nhập'),
        ),
      ],
    );
  }
}

class ForgotPanel extends StatefulWidget {
  const ForgotPanel({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  State<ForgotPanel> createState() => _ForgotPanelState();
}

class _ForgotPanelState extends State<ForgotPanel> {
  final email = TextEditingController();
  final otp = TextEditingController();

  bool sent = false;

  @override
  void dispose() {
    email.dispose();
    otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: sent ? 'Xác nhận mã OTP' : 'Quên mật khẩu',
      subtitle: sent
          ? 'Mã xác nhận đã được gửi đến email của bạn.'
          : 'Nhập thông tin để nhận mã khôi phục qua email của bạn.',
      children: [
        AppTextField(
          controller: email,
          hint: 'Email sinh viên',
          keyboardType: TextInputType.emailAddress,
        ),
        if (sent) ...[
          const SizedBox(height: 12),
          AppTextField(
            controller: otp,
            hint: 'Mã xác nhận',
            keyboardType: TextInputType.number,
          ),
        ],
        const SizedBox(height: 18),
        PrimaryButton(
          text: sent ? 'Xác nhận mã OTP' : 'Gửi mã xác nhận',
          onPressed: () {
            if (sent) {
              widget.onBack();
            } else {
              setState(() {
                sent = true;
              });
            }
          },
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: widget.onBack,
          child: const Text('Bạn đã nhớ mật khẩu? Đăng nhập'),
        ),
      ],
    );
  }
}
