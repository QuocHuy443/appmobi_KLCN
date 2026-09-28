import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'notification_badge_widget.dart';
import '../screens/notifications/notifications_screen.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.medical100,
                child: Text(
                  'NA',
                  style: TextStyle(
                    color: AppColors.medical700,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nguyễn Văn An',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.slate800)),
                  Text('Mã BN: BN00291',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.phone_in_talk, color: Colors.redAccent),
                onPressed: () {},
              ),
              NotificationBadgeWidget(
                count: 3,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
