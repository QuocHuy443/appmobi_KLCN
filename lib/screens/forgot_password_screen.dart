import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../services/patient_api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _api = PatientApiService();
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  Timer? _timer;
  DateTime? _expiry;
  DateTime? _resendAt;
  int _step = 1;
  bool _busy = false;
  bool _showPassword = false;
  bool _showConfirmation = false;
  String? _error;
  String? _info;

  int _secondsUntil(DateTime? end) => end == null
      ? 0
      : (end.difference(DateTime.now()).inMilliseconds / 1000)
          .ceil()
          .clamp(0, 300);

  String get _countdown {
    final seconds = _secondsUntil(_expiry);
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _send() async {
    if (_busy || (_step == 1 && !_formKey.currentState!.validate())) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final response = await _api.sendForgotPasswordOtp(_email.text.trim());
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        _step = 2;
        _otp.clear();
        _expiry = now.add(Duration(
            seconds: response['expires_in'] is int
                ? response['expires_in'] as int
                : 300));
        _resendAt = now.add(Duration(
            seconds: response['resend_after'] is int
                ? response['resend_after'] as int
                : 60));
        _info = (response['message'] ?? 'Mã OTP đã được gửi.').toString();
      });
      _startTimer();
    } catch (error) {
      if (mounted) {
        setState(
            () => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await _api.verifyForgotPasswordOtp(
          email: _email.text.trim(), otpCode: _otp.text.trim());
      if (mounted) setState(() => _step = 3);
    } catch (error) {
      if (mounted) {
        setState(
            () => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await _api.resetForgotPassword(
        identifier: _email.text.trim(),
        otpCode: _otp.text.trim(),
        newPassword: _password.text,
        confirmPassword: _confirmation.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(message);
    } catch (error) {
      if (mounted) {
        setState(
            () => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.medical600),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.slate50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.slate200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.medical600, width: 2)),
      );

  Widget _passwordField(TextEditingController controller, String label,
          bool visible, VoidCallback toggle) =>
      TextFormField(
        controller: controller,
        enabled: !_busy,
        obscureText: !visible,
        textInputAction: controller == _password
            ? TextInputAction.next
            : TextInputAction.done,
        decoration: _decoration(label, Icons.lock_outline_rounded,
            suffix: IconButton(
                onPressed: toggle,
                icon: Icon(visible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined))),
        validator: (value) {
          if (controller == _password &&
              (value == null ||
                  value.length < 6 ||
                  value.length > 128 ||
                  value.trim() != value)) {
            return 'Mật khẩu cần từ 6 đến 128 ký tự, không có khoảng trắng đầu/cuối.';
          }
          if (controller == _confirmation && value != _password.text) {
            return 'Mật khẩu xác nhận không khớp.';
          }
          return null;
        },
      );

  @override
  Widget build(BuildContext context) {
    final title = _step == 1
        ? 'Quên mật khẩu'
        : _step == 2
            ? 'Xác thực mã OTP'
            : 'Đặt lại mật khẩu';
    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
          backgroundColor: AppColors.slate100,
          title: const Text('H2T Care'),
          foregroundColor: AppColors.medical700),
      body: SafeArea(
        child: Center(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                                color: AppColors.medical600,
                                borderRadius: BorderRadius.circular(23)),
                            child: const Icon(Icons.local_hospital_rounded,
                                color: Colors.white, size: 42)),
                        const SizedBox(height: 14),
                        const Text('H2T Healthcare',
                            style: TextStyle(
                                color: AppColors.medical700,
                                fontSize: 19,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.slate200),
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.slate900
                                        .withValues(alpha: 0.06),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10))
                              ]),
                          child: Form(
                              key: _formKey,
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text('BƯỚC $_step / 3',
                                        style: const TextStyle(
                                            color: AppColors.medical600,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.2)),
                                    const SizedBox(height: 6),
                                    Text(title,
                                        style: const TextStyle(
                                            color: AppColors.slate900,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 8),
                                    Text(
                                        _step == 1
                                            ? 'Nhập email đã đăng ký với phòng khám.'
                                            : _step == 2
                                                ? 'Nhập mã 6 số được gửi tới ${_email.text.trim()}.'
                                                : 'Tạo mật khẩu mới cho tài khoản của bạn.',
                                        style: const TextStyle(
                                            color: AppColors.slate600,
                                            fontSize: 14)),
                                    const SizedBox(height: 24),
                                    if (_step == 1)
                                      TextFormField(
                                        controller: _email,
                                        enabled: !_busy,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        autofillHints: const [
                                          AutofillHints.email
                                        ],
                                        decoration: _decoration(
                                            'Email', Icons.email_outlined),
                                        validator: (value) => value == null ||
                                                !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                                    .hasMatch(value.trim())
                                            ? 'Email không đúng định dạng.'
                                            : null,
                                      ),
                                    if (_step == 2) ...[
                                      TextFormField(
                                          controller: _otp,
                                          enabled: !_busy,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(6)
                                          ],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 22,
                                              letterSpacing: 8,
                                              fontWeight: FontWeight.bold),
                                          decoration: _decoration('Mã OTP',
                                              Icons.verified_user_outlined),
                                          validator: (value) => value == null ||
                                                  !RegExp(r'^[0-9]{6}$')
                                                      .hasMatch(value)
                                              ? 'Nhập đúng 6 chữ số OTP.'
                                              : null),
                                      const SizedBox(height: 12),
                                      Text('Mã hết hạn sau $_countdown',
                                          style: const TextStyle(
                                              color: AppColors.slate600)),
                                      TextButton(
                                          onPressed: _busy ||
                                                  _secondsUntil(_resendAt) > 0
                                              ? null
                                              : _send,
                                          child: Text(_secondsUntil(_resendAt) >
                                                  0
                                              ? 'Gửi lại sau ${_secondsUntil(_resendAt)} giây'
                                              : 'Gửi lại mã')),
                                    ],
                                    if (_step == 3) ...[
                                      _passwordField(
                                          _password,
                                          'Mật khẩu mới',
                                          _showPassword,
                                          () => setState(() =>
                                              _showPassword = !_showPassword)),
                                      const SizedBox(height: 16),
                                      _passwordField(
                                          _confirmation,
                                          'Xác nhận mật khẩu',
                                          _showConfirmation,
                                          () => setState(() =>
                                              _showConfirmation =
                                                  !_showConfirmation)),
                                    ],
                                    if (_info != null) ...[
                                      const SizedBox(height: 14),
                                      Text(_info!,
                                          style: const TextStyle(
                                              color: AppColors.medical700))
                                    ],
                                    if (_error != null) ...[
                                      const SizedBox(height: 14),
                                      Text(_error!,
                                          style: const TextStyle(
                                              color: AppColors.rose500))
                                    ],
                                    const SizedBox(height: 22),
                                    FilledButton(
                                      onPressed: _busy
                                          ? null
                                          : _step == 1
                                              ? _send
                                              : _step == 2
                                                  ? _verify
                                                  : _reset,
                                      style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.medical600,
                                          minimumSize:
                                              const Size.fromHeight(52),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14))),
                                      child: _busy
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2))
                                          : Text(_step == 1
                                              ? 'Gửi mã OTP'
                                              : _step == 2
                                                  ? 'Xác thực mã'
                                                  : 'Lưu mật khẩu mới'),
                                    ),
                                  ])),
                        ),
                        const SizedBox(height: 18),
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Quay lại đăng nhập')),
                      ],
                    )))),
      ),
    );
  }
}
