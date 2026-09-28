import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authVm = Provider.of<AuthViewModel>(context);
    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FlutterLogo(size: 120),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                        validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập email' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Mật khẩu', prefixIcon: Icon(Icons.lock)),
                        validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu', prefixIcon: Icon(Icons.lock)),
                        validator: (value) => (value != _passwordCtrl.text) ? 'Mật khẩu không khớp' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                authVm.isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // Placeholder for registration logic
                            await Future.delayed(const Duration(seconds: 1));
                            if (mounted) {
                              Navigator.of(context).pushReplacementNamed('/login');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: AppColors.medical600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Đăng ký'),
                      ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                  child: const Text('Đã có tài khoản? Đăng nhập'),
                ),
                if (authVm.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(authVm.errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
