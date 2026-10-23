import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../main_navigation_screen.dart';

enum AuthMode { login, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.initialMode = AuthMode.login});

  final AuthMode initialMode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AuthMode _mode = widget.initialMode;
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthDateController = TextEditingController();
  String _gender = 'Nam';
  bool _obscurePassword = true;

  bool get _isRegistering => _mode == AuthMode.register;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = context.read<AuthViewModel>();
    if (_isRegistering) {
      await authViewModel.register(
        name: _nameController.text.trim(),
        phone: _identifierController.text.trim(),
        birthDate: _birthDateController.text,
        gender: _gender,
        password: _passwordController.text,
        email: _emailController.text.trim(),
      );
    } else {
      await authViewModel.login(
        _identifierController.text.trim(),
        _passwordController.text,
      );
    }

    if (!mounted) return;
    if (authViewModel.currentUser != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else if (authViewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authViewModel.errorMessage!)),
      );
    }
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
    final authViewModel = context.watch<AuthViewModel>();

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
                      _buildField(
                        controller: _birthDateController,
                        label: 'Ngày sinh',
                        hint: 'Chọn ngày sinh',
                        icon: Icons.calendar_today_outlined,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Vui lòng chọn ngày sinh'
                            : null,
                        onTap: _selectBirthDate,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Giới tính',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                          DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                          DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _gender = value);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildField(
                      controller: _identifierController,
                      label: _isRegistering
                          ? 'Số điện thoại'
                          : 'Tên đăng nhập hoặc số điện thoại',
                      hint: _isRegistering
                          ? 'Số điện thoại đăng ký tài khoản'
                          : 'Nhập tên đăng nhập hoặc số điện thoại',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: (value) => value == null ||
                              value.trim().isEmpty
                          ? _isRegistering
                              ? 'Vui lòng nhập số điện thoại'
                              : 'Vui lòng nhập tên đăng nhập hoặc số điện thoại'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    if (_isRegistering) ...[
                      _buildField(
                        controller: _emailController,
                        label: 'Email (không bắt buộc)',
                        hint: 'example@email.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (_) => null,
                      ),
                      const SizedBox(height: 16),
                    ],
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
                    if (_isRegistering) const SizedBox(height: 20),
                    SizedBox(
                      height: 54,
                      child: authViewModel.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              onPressed: _submit,
                              icon: Icon(_isRegistering
                                  ? Icons.person_add_alt_1
                                  : Icons.login),
                              label: Text(_isRegistering
                                  ? 'Đăng ký tài khoản'
                                  : 'Đăng nhập'),
                            ),
                    ),
                    if (authViewModel.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        authViewModel.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
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
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      readOnly: onTap != null,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (selected == null) return;
    _birthDateController.text = '${selected.year.toString().padLeft(4, '0')}-'
        '${selected.month.toString().padLeft(2, '0')}-'
        '${selected.day.toString().padLeft(2, '0')}';
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
