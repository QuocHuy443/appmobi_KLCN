import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import 'main_navigation_screen.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthViewModel>().clearError();
    });
  }

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
    } else if (authViewModel.errorMessage != null &&
        authViewModel.errorMessage!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(authViewModel.errorMessage!),
        ),
      );
    }
  }

  void _quickFillAndLogin(String phone, String password) {
    _identifierController.text = phone;
    _passwordController.text = password;
    _submit();
  }

  void _switchMode(AuthMode mode) {
    if (_mode == mode) return;
    context.read<AuthViewModel>().clearError();
    setState(() => _mode = mode);
    _formKey.currentState?.reset();
  }

  void _exitToHome() {
    context.read<AuthViewModel>().clearError();
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
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _exitToHome,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.medical700,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.slate200),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text(
                            'Thoát về trang chủ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _BrandMark(),
                      const SizedBox(height: 24),
                      Text(
                        _isRegistering
                            ? 'Tạo tài khoản bệnh nhân'
                            : 'Chào mừng trở lại',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.slate900,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isRegistering
                            ? 'Quản lý lịch khám và hồ sơ sức khỏe của bạn.'
                            : 'Đăng nhập để tiếp tục chăm sóc sức khỏe cùng H2T.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.slate600,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // KHỐI CARD NHẬP LIỆU TÁCH RIÊNG RÕ RÀNG
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.slate200,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.slate900.withValues(alpha: 0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_isRegistering) ...[
                              _buildField(
                                controller: _nameController,
                                label: 'Họ và tên',
                                hint: 'Nhập họ và tên (VD: Nguyễn Văn An)',
                                icon: Icons.person_outline_rounded,
                                textInputAction: TextInputAction.next,
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Vui lòng nhập họ và tên'
                                        : null,
                              ),
                              const SizedBox(height: 18),
                              _buildField(
                                controller: _birthDateController,
                                label: 'Ngày sinh',
                                hint: 'Chọn ngày tháng năm sinh',
                                icon: Icons.calendar_today_rounded,
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'Vui lòng chọn ngày sinh'
                                        : null,
                                onTap: _selectBirthDate,
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Giới tính',
                                style: TextStyle(
                                  color: AppColors.slate800,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _gender,
                                style: const TextStyle(
                                  color: AppColors.slate900,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                dropdownColor: Colors.white,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.slate50,
                                  prefixIcon: const Icon(
                                    Icons.wc_rounded,
                                    color: AppColors.medical600,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: AppColors.slate200,
                                      width: 1.4,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: AppColors.medical600,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Nam',
                                    child: Text('Nam'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Nữ',
                                    child: Text('Nữ'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Khác',
                                    child: Text('Khác'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _gender = value);
                                  }
                                },
                              ),
                              const SizedBox(height: 18),
                            ],
                            _buildField(
                              controller: _identifierController,
                              label: _isRegistering
                                  ? 'Số điện thoại'
                                  : 'Tên đăng nhập hoặc số điện thoại',
                              hint: _isRegistering
                                  ? 'Nhập số điện thoại 10 số'
                                  : 'VD: 0901234561 hoặc bn_1',
                              icon: Icons.phone_android_rounded,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? _isRegistering
                                          ? 'Vui lòng nhập số điện thoại'
                                          : 'Vui lòng nhập tên đăng nhập hoặc số điện thoại'
                                      : null,
                            ),
                            const SizedBox(height: 18),
                            if (_isRegistering) ...[
                              _buildField(
                                controller: _emailController,
                                label: 'Email (không bắt buộc)',
                                hint: 'example@email.com',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (_) => null,
                              ),
                              const SizedBox(height: 18),
                            ],
                            _buildField(
                              controller: _passwordController,
                              label: 'Mật khẩu',
                              hint: 'Nhập mật khẩu (mẫu: 123456)',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Hiện mật khẩu'
                                    : 'Ẩn mật khẩu',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.slate600,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (value) =>
                                  value == null || value.length < 6
                                      ? 'Mật khẩu cần ít nhất 6 ký tự'
                                      : null,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                          ],
                        ),
                      ),

                      // KHOẢNG CÁCH TÁCH BIỆT RÕ RÀNG GIỮA KHUNG NHẬP VÀ NÚT ĐĂNG NHẬP
                      const SizedBox(height: 28),

                      // NÚT ĐĂNG NHẬP / ĐĂNG KÝ HIỆN ĐẠI, NỔI BẬT
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF059669),
                              Color(0xFF10B981),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.medical600.withValues(alpha: 0.38),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: authViewModel.isLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                icon: Icon(
                                  _isRegistering
                                      ? Icons.person_add_alt_1_rounded
                                      : Icons.login_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                label: Text(
                                  _isRegistering
                                      ? 'Đăng ký tài khoản'
                                      : 'Đăng nhập',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                      ),

                      if (!_isRegistering) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.medical100),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.flash_on_rounded,
                                    size: 16,
                                    color: AppColors.medical600,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Đăng nhập nhanh tài khoản mẫu (1 chạm):',
                                    style: TextStyle(
                                      color: AppColors.slate700,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  ActionChip(
                                    backgroundColor: AppColors.medical50,
                                    side: const BorderSide(
                                      color: AppColors.medical200,
                                    ),
                                    avatar: const Icon(
                                      Icons.verified_user_rounded,
                                      size: 16,
                                      color: AppColors.medical700,
                                    ),
                                    label: const Text(
                                      'BN có BHYT (0901234561)',
                                      style: TextStyle(
                                        color: AppColors.medical700,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    onPressed: () => _quickFillAndLogin(
                                      '0901234561',
                                      '123456',
                                    ),
                                  ),
                                  ActionChip(
                                    backgroundColor: AppColors.slate100,
                                    side: const BorderSide(
                                      color: AppColors.slate200,
                                    ),
                                    avatar: const Icon(
                                      Icons.person_rounded,
                                      size: 16,
                                      color: AppColors.slate700,
                                    ),
                                    label: const Text(
                                      'BN 2 (0901234562)',
                                      style: TextStyle(
                                        color: AppColors.slate800,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    onPressed: () => _quickFillAndLogin(
                                      '0901234562',
                                      '123456',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (authViewModel.errorMessage != null &&
                          authViewModel.errorMessage!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFDC2626),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  authViewModel.errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFB91C1C),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                            style: const TextStyle(
                              color: AppColors.slate700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _switchMode(
                              _isRegistering
                                  ? AuthMode.login
                                  : AuthMode.register,
                            ),
                            child: Text(
                              _isRegistering ? 'Đăng nhập' : 'Đăng ký ngay',
                              style: const TextStyle(
                                color: AppColors.medical700,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bằng việc tiếp tục, bạn đồng ý với Điều khoản sử dụng và Chính sách bảo mật của H2T Healthcare.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.slate500,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.slate800,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          readOnly: onTap != null,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          onTap: onTap,
          style: const TextStyle(
            color: AppColors.slate900,
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
          cursorColor: AppColors.medical600,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.slate400,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            prefixIcon: Icon(icon, color: AppColors.medical600, size: 21),
            suffixIcon: suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.slate200,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.medical600,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 2.0,
              ),
            ),
          ),
        ),
      ],
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
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3310B981),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_hospital_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'H2T Healthcare',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.medical700,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Chăm sóc sức khỏe trong tầm tay',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.slate600,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
