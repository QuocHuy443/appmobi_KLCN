import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../screens/auth_screen.dart';
import '../screens/notifications_screen.dart';

class HeaderWidget extends StatelessWidget {
  final int unreadCount;
  final VoidCallback? onRefresh;

  const HeaderWidget({
    super.key,
    this.unreadCount = 0,
    this.onRefresh,
  });

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'BN';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final displayName = user != null && user.name.isNotEmpty ? user.name : 'Khách vãng lai';
    final subTitle = user != null && user.patientCode.isNotEmpty
        ? 'Mã BN: ${user.patientCode}'
        : 'Chạm để đăng nhập tài khoản';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: InkWell(
              onTap: user == null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      );
                    }
                  : null,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.medical100,
                    child: Text(
                      _initials(displayName),
                      style: const TextStyle(
                        color: AppColors.medical700,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.slate800,
                          ),
                        ),
                        Text(
                          subTitle,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Hotline cấp cứu 1900 6868',
                icon: const Icon(Icons.phone_in_talk, color: Colors.redAccent),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tổng đài Cấp cứu & CSKH H2T Care: 1900 6868 (Trực 24/7)'),
                    ),
                  );
                },
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.bell, size: 22, color: AppColors.slate800),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                      onRefresh?.call();
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
