import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../main_navigation_screen.dart';

enum AuthMode { login, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const _demoEmail = 'patient@h2t.vn';
  static const _demoPassword = '123456';
  AuthMode _mode = AuthMode.login;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;

  bool get _isRegistering => _mode == AuthMode.register;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (!_isRegistering &&
        (_emailController.text.trim() != _demoEmail ||
            _passwordController.text != _demoPassword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Thông tin đăng nhập chưa đúng. Hãy dùng tài khoản test.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const MainNavigationScreen(isLoggedIn: true),
      ),
    );
  }

  void _fillDemoAccount() {
    setState(() {
      _emailController.text = _demoEmail;
      _passwordController.text = _demoPassword;
    });
  }

  void _switchMode(AuthMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    _formKey.currentState?.reset();
  }

  void _exitToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _exitToHome,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Thoát về trang chủ'),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const _BrandMark(),
                    const SizedBox(height: 30),
                    Text(
                      _isRegistering
                          ? 'Tạo tài khoản bệnh nhân'
                          : 'Chào mừng trở lại',
                      style: const TextStyle(
                        color: AppColors.slate900,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRegistering
                          ? 'Quản lý lịch khám và hồ sơ sức khỏe của bạn.'
                          : 'Đăng nhập để tiếp tục chăm sóc sức khỏe cùng H2T.',
                      style: const TextStyle(
                          color: AppColors.slate500, fontSize: 15),
                    ),
                    const SizedBox(height: 28),
                    if (_isRegistering) ...[
                      _buildField(
                        controller: _nameController,
                        label: 'Họ và tên',
                        hint: 'Nguyễn Văn An',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Vui lòng nhập họ và tên'
                                : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildField(
                      controller: _emailController,
                      label: 'Email hoặc số điện thoại',
                      hint: 'Nhập thông tin đăng nhập',
                      icon: Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Vui lòng nhập email hoặc số điện thoại'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _passwordController,
                      label: 'Mật khẩu',
                      hint: 'Tối thiểu 6 ký tự',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      suffixIcon: IconButton(
                        tooltip:
                            _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'Mật khẩu cần ít nhất 6 ký tự'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (!_isRegistering)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Quên mật khẩu?'),
                        ),
                      )
                    else
                      const SizedBox(height: 20),
                    if (!_isRegistering) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.medical50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.medical100),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.science_outlined,
                                color: AppColors.medical700),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Tài khoản test: patient@h2t.vn\nMật khẩu: 123456',
                                style: TextStyle(
                                  color: AppColors.slate700,
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _fillDemoAccount,
                              child: const Text('Điền nhanh'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: Icon(_isRegistering
                            ? Icons.person_add_alt_1
                            : Icons.login),
                        label: Text(
                            _isRegistering ? 'Đăng ký tài khoản' : 'Đăng nhập'),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isRegistering
                              ? 'Đã có tài khoản?'
                              : 'Chưa có tài khoản?',
                          style: const TextStyle(color: AppColors.slate500),
                        ),
                        TextButton(
                          onPressed: () => _switchMode(
                            _isRegistering ? AuthMode.login : AuthMode.register,
                          ),
                          child: Text(
                              _isRegistering ? 'Đăng nhập' : 'Đăng ký ngay'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bằng việc tiếp tục, bạn đồng ý với Điều khoản sử dụng và Chính sách bảo mật của H2T Healthcare.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.slate400, fontSize: 12, height: 1.4),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.medical600,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x2410B981),
                  blurRadius: 20,
                  offset: Offset(0, 10)),
            ],
          ),
          child: const Icon(Icons.local_hospital_rounded,
              color: Colors.white, size: 52),
        ),
        const SizedBox(height: 14),
        const Text(
          'H2T Healthcare',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppColors.medical700,
              fontSize: 18,
              fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Chăm sóc sức khỏe trong tầm tay',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.slate500, fontSize: 13),
        ),
      ],
    );
  }
}
