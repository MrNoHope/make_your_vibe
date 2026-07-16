import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  static const _background = Colors.black;
  static const _surface = Color(0xFF1F1F1F);
  static const _surfaceSoft = Color(0xFF252525);
  static const _accent = Color(0xFFFF2D55);
  static const _muted = Color(0xFF8A8A8A);

  AuthMode mode = AuthMode.login;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  bool loading = false;
  bool showPassword = false;
  bool showEmailLoginForm = false;
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

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        errorMessage = 'Nhập email hợp lệ để tiếp tục.';
      });
      return;
    }

    if (!isForgotMode && password.length < 6) {
      setState(() {
        errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự.';
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
          showEmailLoginForm = true;
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
        errorMessage = _friendlyAuthError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String _friendlyAuthError(Object error) {
    final raw = '$error';
    if (raw.contains('email-already-in-use')) {
      return 'Email này đã được đăng ký. Hãy đăng nhập.';
    }
    if (raw.contains('invalid-credential') ||
        raw.contains('wrong-password') ||
        raw.contains('user-not-found')) {
      return 'Email hoặc mật khẩu không đúng.';
    }
    if (raw.contains('weak-password')) {
      return 'Mật khẩu quá yếu. Hãy dùng ít nhất 6 ký tự.';
    }
    if (raw.contains('invalid-email')) {
      return 'Email không hợp lệ.';
    }
    if (raw.contains('operation-not-allowed')) {
      return 'Firebase chưa bật đăng nhập Email/Password.';
    }
    if (raw.contains('network-request-failed')) {
      return 'Mất kết nối mạng. Thử lại sau.';
    }
    return raw;
  }

  void switchMode(AuthMode next) {
    setState(() {
      mode = next;
      errorMessage = '';
      showEmailLoginForm = false;
      showPassword = false;
    });
  }

  void openEmailLogin() {
    setState(() {
      showEmailLoginForm = true;
      errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final systemStyle = SystemUiOverlayStyle.light.copyWith(
      statusBarColor: _background,
      systemNavigationBarColor: _background,
      systemNavigationBarDividerColor: _background,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemStyle,
      child: Scaffold(
        backgroundColor: _background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              Offstage(
                offstage: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Row(
                    children: [
                      _TopIconButton(
                        tooltip: 'Trợ giúp',
                        icon: Icons.help_outline_rounded,
                        onPressed: showHelp,
                      ),
                      const Spacer(),
                      _TopIconButton(
                        tooltip: 'Đóng',
                        icon: Icons.close_rounded,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    30,
                    mode == AuthMode.login && !showEmailLoginForm ? 82 : 42,
                    30,
                    26,
                  ),
                  children: [
                    _AuthLogo(
                      size: mode == AuthMode.login && !showEmailLoginForm
                          ? 76
                          : 60,
                    ),
                    const SizedBox(height: 22),
                    _AuthTitle(text: _title),
                    SizedBox(height: isRegisterMode ? 34 : 38),
                    _modeBody,
                  ],
                ),
              ),
              const _TermsText(),
              _BottomAuthSwitch(
                mode: mode,
                onLogin: () => switchMode(AuthMode.login),
                onRegister: () => switchMode(AuthMode.register),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _title {
    return switch (mode) {
      AuthMode.login => showEmailLoginForm
          ? 'Đăng nhập bằng email'
          : 'Đăng nhập vào Make Your Vibe',
      AuthMode.register => 'Đăng ký Make Your Vibe',
      AuthMode.forgot => 'Khôi phục tài khoản',
    };
  }

  Widget get _modeBody {
    if (mode == AuthMode.register) {
      return _RegisterForm(
        loading: loading,
        errorMessage: errorMessage,
        nameController: nameController,
        emailController: emailController,
        passwordController: passwordController,
        showPassword: showPassword,
        onPasswordVisibilityChanged: togglePasswordVisibility,
        onSubmit: submit,
        onGoogle: signInWithGoogle,
        onFacebook: signInWithFacebook,
      );
    }

    if (mode == AuthMode.forgot) {
      return _ForgotForm(
        loading: loading,
        errorMessage: errorMessage,
        emailController: emailController,
        onSubmit: submit,
      );
    }

    if (showEmailLoginForm) {
      return _EmailLoginForm(
        loading: loading,
        errorMessage: errorMessage,
        emailController: emailController,
        passwordController: passwordController,
        showPassword: showPassword,
        onPasswordVisibilityChanged: togglePasswordVisibility,
        onSubmit: submit,
        onForgot: () => switchMode(AuthMode.forgot),
        onGoogle: signInWithGoogle,
        onFacebook: signInWithFacebook,
      );
    }

    return _LoginOptions(
      loading: loading,
      errorMessage: errorMessage,
      onEmail: openEmailLogin,
      onGoogle: signInWithGoogle,
      onFacebook: signInWithFacebook,
    );
  }

  void togglePasswordVisibility() {
    setState(() {
      showPassword = !showPassword;
    });
  }

  void showHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trợ giúp đăng nhập',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Dùng email/mật khẩu hoặc tài khoản mạng xã hội đã liên kết để vào Make Your Vibe.',
                  style: TextStyle(
                    color: _muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Đã hiểu'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LoginOptions extends StatelessWidget {
  final bool loading;
  final String errorMessage;
  final VoidCallback onEmail;
  final VoidCallback onGoogle;
  final VoidCallback onFacebook;

  const _LoginOptions({
    required this.loading,
    required this.errorMessage,
    required this.onEmail,
    required this.onGoogle,
    required this.onFacebook,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AuthProviderButton(
          onPressed: loading ? null : onEmail,
          logo: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 27,
          ),
          label: 'Sử dụng email/mật khẩu',
        ),
        const SizedBox(height: 14),
        AuthProviderButton(
          onPressed: loading ? null : onFacebook,
          logo: const FacebookLogo(),
          label: 'Tiếp tục với Facebook',
        ),
        const SizedBox(height: 14),
        AuthProviderButton(
          onPressed: loading ? null : onGoogle,
          logo: const GoogleLogo(),
          label: 'Tiếp tục với Google',
        ),
        _AuthMessage(errorMessage: errorMessage),
      ],
    );
  }
}

class _EmailLoginForm extends StatelessWidget {
  final bool loading;
  final String errorMessage;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool showPassword;
  final VoidCallback onPasswordVisibilityChanged;
  final VoidCallback onSubmit;
  final VoidCallback onForgot;
  final VoidCallback onGoogle;
  final VoidCallback onFacebook;

  const _EmailLoginForm({
    required this.loading,
    required this.errorMessage,
    required this.emailController,
    required this.passwordController,
    required this.showPassword,
    required this.onPasswordVisibilityChanged,
    required this.onSubmit,
    required this.onForgot,
    required this.onGoogle,
    required this.onFacebook,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AuthTextField(
          controller: emailController,
          hintText: 'Email',
          icon: Icons.mail_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        _AuthTextField(
          controller: passwordController,
          hintText: 'Mật khẩu',
          icon: Icons.lock_rounded,
          obscureText: !showPassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          suffix: IconButton(
            tooltip: showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
            onPressed: onPasswordVisibilityChanged,
            icon: Icon(
              showPassword
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: _AuthScreenState._muted,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: loading ? null : onForgot,
            child: const Text('Quên mật khẩu?'),
          ),
        ),
        const SizedBox(height: 6),
        _PrimaryAuthButton(
          label: 'Tiếp tục',
          loading: loading,
          onPressed: onSubmit,
        ),
        const SizedBox(height: 24),
        const AuthDivider(),
        const SizedBox(height: 24),
        AuthProviderButton(
          onPressed: loading ? null : onFacebook,
          logo: const FacebookLogo(),
          label: 'Tiếp tục với Facebook',
        ),
        const SizedBox(height: 14),
        AuthProviderButton(
          onPressed: loading ? null : onGoogle,
          logo: const GoogleLogo(),
          label: 'Tiếp tục với Google',
        ),
        _AuthMessage(errorMessage: errorMessage),
      ],
    );
  }
}

class _RegisterForm extends StatelessWidget {
  final bool loading;
  final String errorMessage;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool showPassword;
  final VoidCallback onPasswordVisibilityChanged;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;
  final VoidCallback onFacebook;

  const _RegisterForm({
    required this.loading,
    required this.errorMessage,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.showPassword,
    required this.onPasswordVisibilityChanged,
    required this.onSubmit,
    required this.onGoogle,
    required this.onFacebook,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AuthTextField(
          controller: nameController,
          hintText: 'Tên hiển thị',
          icon: Icons.person_rounded,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        _AuthTextField(
          controller: emailController,
          hintText: 'Email',
          icon: Icons.mail_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        _AuthTextField(
          controller: passwordController,
          hintText: 'Mật khẩu',
          icon: Icons.lock_rounded,
          obscureText: !showPassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          suffix: IconButton(
            tooltip: showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
            onPressed: onPasswordVisibilityChanged,
            icon: Icon(
              showPassword
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: _AuthScreenState._muted,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _PrimaryAuthButton(
          label: 'Tiếp tục',
          loading: loading,
          onPressed: onSubmit,
        ),
        const SizedBox(height: 24),
        const AuthDivider(),
        const SizedBox(height: 24),
        AuthProviderButton(
          onPressed: loading ? null : onFacebook,
          logo: const FacebookLogo(),
          label: 'Tiếp tục với Facebook',
        ),
        const SizedBox(height: 14),
        AuthProviderButton(
          onPressed: loading ? null : onGoogle,
          logo: const GoogleLogo(),
          label: 'Tiếp tục với Google',
        ),
        _AuthMessage(errorMessage: errorMessage),
      ],
    );
  }
}

class _ForgotForm extends StatelessWidget {
  final bool loading;
  final String errorMessage;
  final TextEditingController emailController;
  final VoidCallback onSubmit;

  const _ForgotForm({
    required this.loading,
    required this.errorMessage,
    required this.emailController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AuthTextField(
          controller: emailController,
          hintText: 'Email của bạn',
          icon: Icons.mail_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 28),
        _PrimaryAuthButton(
          label: 'Gửi email khôi phục',
          loading: loading,
          onPressed: onSubmit,
        ),
        _AuthMessage(errorMessage: errorMessage),
      ],
    );
  }
}

class _AuthTitle extends StatelessWidget {
  final String text;

  const _AuthTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w900,
          height: 1.05,
        ),
      ),
    );
  }
}

class _AuthLogo extends StatelessWidget {
  final double size;

  const _AuthLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppLogo(size: size),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  const _AuthTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffix,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        onSubmitted: onSubmitted,
        cursorColor: _AuthScreenState._accent,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: _AuthScreenState._surface,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: _AuthScreenState._muted,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _PrimaryAuthButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _AuthScreenState._accent,
          disabledBackgroundColor: _AuthScreenState._accent.withValues(
            alpha: 0.46,
          ),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        child: loading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _AuthMessage extends StatelessWidget {
  final String errorMessage;

  const _AuthMessage({required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    if (errorMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    final success = errorMessage.startsWith('Đã gửi');

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        errorMessage,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: success ? const Color(0xFF74E26B) : const Color(0xFFFF6B81),
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _TopIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 42,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

class _TermsText extends StatelessWidget {
  const _TermsText();

  @override
  Widget build(BuildContext context) {
    const linkStyle = TextStyle(
      color: Color(0xFF65BFFF),
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 6, 26, 18),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            color: _AuthScreenState._muted,
            fontSize: 13,
            height: 1.32,
            fontWeight: FontWeight.w600,
          ),
          children: const [
            TextSpan(
              text:
                  'Bằng việc tiếp tục với tài khoản có vị trí tại Việt Nam, bạn đồng ý với ',
            ),
            TextSpan(text: 'Điều khoản Dịch vụ', style: linkStyle),
            TextSpan(
              text: ', đồng thời xác nhận rằng bạn đã đọc ',
            ),
            TextSpan(text: 'Chính sách Quyền riêng tư', style: linkStyle),
            TextSpan(text: ' của chúng tôi.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _BottomAuthSwitch extends StatelessWidget {
  final AuthMode mode;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const _BottomAuthSwitch({
    required this.mode,
    required this.onLogin,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final registering = mode == AuthMode.register;

    return Container(
      width: double.infinity,
      color: _AuthScreenState._surfaceSoft,
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              registering ? 'Bạn đã có tài khoản?' : 'Bạn không có tài khoản?',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFD6D6D6),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: registering ? onLogin : onRegister,
            style: TextButton.styleFrom(
              foregroundColor: _AuthScreenState._accent,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: Text(registering ? 'Đăng nhập' : 'Đăng ký'),
          ),
        ],
      ),
    );
  }
}
