import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Tất cả', 'Nhắc hẹn', 'Viện phí', 'Hệ thống'];

  final List<Map<String, dynamic>> _notifications = [
    {
      'type': 'appointment',
      'title': 'Nhắc lịch khám ngày mai',
      'content': 'Bạn có lịch khám Tim mạch với PGS.TS Trần Văn A vào lúc 08:30 ngày mai. Vui lòng đến trước 15 phút.',
      'time': '2 giờ trước',
      'isUnread': true,
      'icon': FontAwesomeIcons.calendarCheck,
      'color': Colors.blue,
    },
    {
      'type': 'billing',
      'title': 'Hóa đơn chưa thanh toán',
      'content': 'Bạn có 1 hóa đơn Viện phí trị giá 1,250,000 đ chưa thanh toán. Hạn chót: 23/09/2026.',
      'time': '1 ngày trước',
      'isUnread': true,
      'icon': FontAwesomeIcons.fileInvoiceDollar,
      'color': Colors.orange,
    },
    {
      'type': 'system',
      'title': 'Cập nhật hệ thống thành công',
      'content': 'Ứng dụng đã được cập nhật lên phiên bản mới nhất với nhiều tính năng và cải thiện hiệu suất.',
      'time': '3 ngày trước',
      'isUnread': false,
      'icon': FontAwesomeIcons.gear,
      'color': AppColors.slate500,
    },
    {
      'type': 'appointment',
      'title': 'Đặt lịch thành công',
      'content': 'Bạn đã đặt lịch khám thành công vào ngày 22/09/2026.',
      'time': '1 tuần trước',
      'isUnread': false,
      'icon': FontAwesomeIcons.checkCircle,
      'color': AppColors.medical600,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filter notifications based on selected index
    final filteredNotifications = _notifications.where((notif) {
      if (_selectedFilterIndex == 0) return true;
      if (_selectedFilterIndex == 1) return notif['type'] == 'appointment';
      if (_selectedFilterIndex == 2) return notif['type'] == 'billing';
      if (_selectedFilterIndex == 3) return notif['type'] == 'system';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: AppColors.medical600),
            onPressed: () {
              // Đánh dấu đã đọc tất cả
              setState(() {
                for (var element in _notifications) {
                  element['isUnread'] = false;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = _selectedFilterIndex == index;
                return ChoiceChip(
                  label: Text(_filters[index]),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFilterIndex = index);
                  },
                  backgroundColor: AppColors.slate100,
                  selectedColor: AppColors.medical100,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.medical700 : AppColors.slate700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide.none,
                );
              },
            ),
          ),
          
          // Notifications List
          Expanded(
            child: ListView.separated(
              itemCount: filteredNotifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.slate200),
              itemBuilder: (context, index) {
                final notif = filteredNotifications[index];
                return InkWell(
                  onTap: () {
                    if (notif['isUnread']) {
                      setState(() {
                        notif['isUnread'] = false;
                      });
                    }
                    // Handle navigation if needed
                  },
                  child: Container(
                    color: notif['isUnread'] ? AppColors.medical50.withOpacity(0.5) : Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (notif['color'] as Color).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: FaIcon(
                              notif['icon'],
                              color: notif['color'],
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif['title'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: notif['isUnread'] ? FontWeight.bold : FontWeight.w600,
                                        color: AppColors.slate800,
                                      ),
                                    ),
                                  ),
                                  if (notif['isUnread'])
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif['content'],
                                style: TextStyle(
                                  color: notif['isUnread'] ? AppColors.slate700 : AppColors.slate500,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                notif['time'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.slate400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
