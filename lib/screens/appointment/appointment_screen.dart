import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/notification_badge_widget.dart';
import '../notifications/notifications_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  int _selectedDateIndex = 0;
  String _selectedTime = '';
  
  final List<String> _specialties = [
    'Nội khoa', 'Nhi khoa', 'Sản phụ khoa', 'Tai mũi họng', 'Răng hàm mặt', 'Mắt', 'Da liễu', 'Tim mạch'
  ];
  
  final List<Map<String, dynamic>> _doctors = [
    {'name': 'PGS.TS Trần Văn A', 'rating': 4.9, 'specialty': 'Tim mạch'},
    {'name': 'BS.CKII Nguyễn Thị B', 'rating': 4.8, 'specialty': 'Nhi khoa'},
    {'name': 'ThS.BS Lê Văn C', 'rating': 4.7, 'specialty': 'Nội khoa'},
  ];

  final List<String> _morningTimes = ['07:30', '08:00', '08:30', '09:00', '09:30', '10:00', '10:30', '11:00'];
  final List<String> _afternoonTimes = ['13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30'];
  final List<String> _bookedTimes = ['08:30', '09:00', '14:00'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt lịch khám'),
        actions: [
          NotificationBadgeWidget(
            count: 2,
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bước 1: Tìm kiếm & Chọn bác sĩ
            _buildSectionTitle('1. Chọn chuyên khoa & Bác sĩ'),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm triệu chứng, bác sĩ, chuyên khoa...',
                prefixIcon: const Icon(Icons.search, color: AppColors.slate400),
                filled: true,
                fillColor: AppColors.slate100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _specialties.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return Chip(
                    label: Text(_specialties[index]),
                    backgroundColor: index == 0 ? AppColors.medical100 : AppColors.slate100,
                    labelStyle: TextStyle(
                      color: index == 0 ? AppColors.medical700 : AppColors.slate700,
                      fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide.none,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _doctors.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final doc = _doctors[index];
                  return Container(
                    width: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.medical100,
                              child: Text(
                                doc['name'].toString().split(' ').last[0],
                                style: const TextStyle(color: AppColors.medical700, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    doc['specialty'],
                                    style: const TextStyle(color: AppColors.slate400, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              doc['rating'].toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Bước 2: Thời gian
            _buildSectionTitle('2. Chọn thời gian'),
            const SizedBox(height: 12),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 14,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = _selectedDateIndex == index;
                  final dayNames = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDateIndex = index),
                    child: Container(
                      width: 60,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.medical600 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppColors.medical600 : AppColors.slate200),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayNames[date.weekday % 7],
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.slate400,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.slate800,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text('Buổi sáng', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _morningTimes.map((time) => _buildTimeChip(time)).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Buổi chiều', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _afternoonTimes.map((time) => _buildTimeChip(time)).toList(),
            ),
            const SizedBox(height: 24),

            // Bước 3: Lý do
            _buildSectionTitle('3. Lý do khám'),
            const SizedBox(height: 12),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Mô tả triệu chứng của bạn (ví dụ: đau đầu, sốt cao...)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.medical500),
                ),
              ),
            ),
            const SizedBox(height: 100), // Không gian cho Bottom Navigation / Button
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: CustomButton(
          text: 'Xác nhận đặt lịch',
          onPressed: () {
            // Confirm action
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.slate800,
      ),
    );
  }

  Widget _buildTimeChip(String time) {
    final isBooked = _bookedTimes.contains(time);
    final isSelected = _selectedTime == time;
    return ChoiceChip(
      label: Text(time),
      selected: isSelected && !isBooked,
      onSelected: isBooked ? null : (selected) {
        if (selected) setState(() => _selectedTime = time);
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.medical100,
      disabledColor: AppColors.slate200,
      labelStyle: TextStyle(
        color: isBooked ? AppColors.slate400 : (isSelected ? AppColors.medical700 : AppColors.slate700),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isBooked ? AppColors.slate200 : (isSelected ? AppColors.medical500 : AppColors.slate200),
        ),
      ),
    );
  }
}