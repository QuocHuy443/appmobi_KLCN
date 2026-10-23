import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/user.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../widgets/qr_modal_widget.dart';
import '../../widgets/notification_badge_widget.dart';
// Note: We need to route to TestResultsScreen and BillingScreen.
// I will just add them to the profile list menu for easy access.
import '../test_results/test_results_screen.dart';
import '../billing/billing_screen.dart';
import '../notifications/notifications_screen.dart';
import '../auth/auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.user});

  final User? user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản của tôi'),
        actions: [
          NotificationBadgeWidget(
            count: 3,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            widget.user == null
                ? _buildGuestHeader(context)
                : _buildHeader(context, widget.user!),
            const SizedBox(height: 24),
            if (widget.user == null)
              _buildGuestActions(context)
            else
              _buildMenuItems(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
      color: Colors.white,
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: AppColors.medical50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline,
                color: AppColors.medical600, size: 40),
          ),
          const SizedBox(height: 14),
          const Text(
            'Bạn chưa đăng nhập',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.slate800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Đăng nhập để quản lý lịch khám, hồ sơ và kết quả sức khỏe.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate500, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _openAuth,
              icon: const Icon(Icons.login),
              label: const Text('Đăng nhập / Đăng ký'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate200),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.medical600),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Các tính năng hồ sơ sẽ mở sau khi bạn đăng nhập.',
                style: TextStyle(color: AppColors.slate600, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAuth() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  Widget _buildHeader(BuildContext context, User user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.slate200)),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.slate100,
                  border: Border.all(color: AppColors.medical100, width: 3),
                  image: const DecorationImage(
                    image: NetworkImage(
                        'https://i.pravatar.cc/150?img=68'), // Placeholder image
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.medical600,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate800),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ID: ${user.patientCode}',
                    style: const TextStyle(
                        color: AppColors.slate600,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // QR
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: QrModalWidget(patientCode: user.patientCode),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.medical50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.medical100),
              ),
              child: const Icon(Icons.qr_code_2,
                  color: AppColors.medical600, size: 32),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildMenuCategory(
            title: 'Dịch vụ y tế',
            items: [
              _buildMenuItem(
                icon: FontAwesomeIcons.microscope,
                title: 'Kết quả xét nghiệm',
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TestResultsScreen()));
                },
              ),
              _buildMenuItem(
                icon: FontAwesomeIcons.fileInvoiceDollar,
                title: 'Hóa đơn & Viện phí',
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const BillingScreen()));
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMenuCategory(
            title: 'Cá nhân',
            items: [
              _buildMenuItem(
                  icon: FontAwesomeIcons.users,
                  title: 'Hồ sơ người thân',
                  onTap: () {}),
              _buildMenuItem(
                  icon: FontAwesomeIcons.creditCard,
                  title: 'Phương thức thanh toán',
                  onTap: () {}),
              _buildMenuItem(
                  icon: FontAwesomeIcons.shieldHalved,
                  title: 'Cài đặt bảo mật & Sinh trắc học',
                  onTap: () {}),
            ],
          ),
          const SizedBox(height: 16),
          _buildMenuCategory(
            title: 'Khác',
            items: [
              _buildMenuItem(
                  icon: FontAwesomeIcons.headset,
                  title: 'Hỗ trợ & CSKH',
                  onTap: () {}),
              _buildMenuItem(
                icon: FontAwesomeIcons.arrowRightFromBracket,
                title: 'Đăng xuất',
                isDestructive: true,
                onTap: () async {
                  await context.read<AuthViewModel>().logout();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Đã đăng xuất khỏi ứng dụng.')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMenuCategory(
      {required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.slate400,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required dynamic icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : AppColors.slate700;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            if (icon is IconData)
              Icon(icon,
                  size: 20,
                  color: isDestructive ? Colors.red : AppColors.slate500)
            else
              FaIcon(icon,
                  size: 20,
                  color: isDestructive ? Colors.red : AppColors.slate500),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isDestructive ? FontWeight.bold : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            if (!isDestructive)
              const Icon(Icons.chevron_right, color: AppColors.slate300),
          ],
        ),
      ),
    );
  }
}
