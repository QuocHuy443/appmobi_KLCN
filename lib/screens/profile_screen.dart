import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import '../widgets/request_error.dart';
import 'auth_screen.dart';
import 'billing_screen.dart';
import 'personal_profile_screen.dart';
import 'feedback_screen.dart';
import 'notifications_screen.dart';
import 'test_results_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.user, this.refreshVersion = 0});
  final User? user;
  final int refreshVersion;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = PatientApiService();
  String? _token, _error;
  bool _loading = false;
  Map<String, dynamic> _profile = {};
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context.watch<AuthViewModel>().currentUser?.token;
    if (token != _token) { _token = token; _profile = {}; _error = null; if (token != null) _load(token); }
  }
  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion && _token != null) _load(_token!);
  }
  Future<void> _load(String token) async {
    setState(() { _loading = true; _error = null; });
    try {
      final profile = await _api.getProfile(token);
      if (!mounted || context.read<AuthViewModel>().currentUser?.token != token) return;
      setState(() { _profile = profile; _loading = false; });
      context.read<AuthViewModel>().updatePatientProfile(token, profile);
    } catch (e) { if (mounted && _token == token) setState(() { _error = '$e'; _loading = false; }); }
  }
  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted && _token != null) _load(_token!);
  }
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.currentUser;
    final avatar = PatientApiService.avatarUrl(_profile['avatar']);
    return Scaffold(backgroundColor: AppColors.slate50,
      appBar: AppBar(title: const Text('Tài khoản'), automaticallyImplyLeading: false),
      body: RefreshIndicator(onRefresh: () async { if (user != null) await _load(user.token); },
        child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(20), children: [
          if (user == null) Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.person_outline, size: 44, color: AppColors.medical600), const SizedBox(height: 16),
            const Text('Bạn chưa đăng nhập', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (auth.errorMessage != null) Text(auth.errorMessage!, style: const TextStyle(color: Colors.red)),
            const Text('Đăng nhập để sử dụng thông tin và dịch vụ cá nhân.'), const SizedBox(height: 16),
            FilledButton(onPressed: () => _open(const AuthScreen()), child: const Text('Đăng nhập / Đăng ký')),
          ]))) else ...[
            Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
              CircleAvatar(radius: 38, backgroundColor: AppColors.medical100, backgroundImage: avatar == null ? null : NetworkImage(avatar), onBackgroundImageError: avatar == null ? null : (_, __) {}, child: avatar == null ? const Icon(Icons.person, size: 38) : null),
              const SizedBox(height: 12), Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('Mã bệnh nhân: ${user.patientCode}'), Text(user.phone),
              const Divider(height: 28), Text('BHYT: ${_profile['bhyt'] ?? 'Chưa cập nhật'}'), Text('Nhóm máu: ${_profile['nhom_mau'] ?? 'Chưa rõ'}'),
            ]))),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) RequestError(message: _error!, onRetry: () => _load(user.token)),
            const SizedBox(height: 16),
            Card(child: Column(children: [
              ListTile(leading: const Icon(Icons.manage_accounts), title: const Text('Thông tin cá nhân & ảnh đại diện'), trailing: const Icon(Icons.chevron_right), onTap: () => _open(const PersonalProfileScreen())),
              ListTile(leading: const Icon(Icons.rate_review), title: const Text('Góp ý & phản hồi'), trailing: const Icon(Icons.chevron_right), onTap: () => _open(const FeedbackScreen())),
              ListTile(leading: const Icon(Icons.receipt_long), title: const Text('Hóa đơn & viện phí'), trailing: const Icon(Icons.chevron_right), onTap: () => _open(const BillingScreen())),
              ListTile(leading: const Icon(Icons.science), title: const Text('Kết quả xét nghiệm'), trailing: const Icon(Icons.chevron_right), onTap: () => _open(const TestResultsScreen())),
              ListTile(leading: const Icon(Icons.notifications), title: const Text('Thông báo'), trailing: const Icon(Icons.chevron_right), onTap: () => _open(const NotificationsScreen())),
            ])),
            const SizedBox(height: 24), OutlinedButton.icon(onPressed: auth.isLoading ? null : auth.logout, icon: const Icon(Icons.logout), label: const Text('Đăng xuất tài khoản')),
          ],
        ])),
    );
  }
}
