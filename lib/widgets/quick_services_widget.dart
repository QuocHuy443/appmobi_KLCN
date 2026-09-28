import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class QuickServicesWidget extends StatelessWidget {
  const QuickServicesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Thay thế FontAwesomeIcons bằng Icons mặc định của Material
    final services = [
      {
        'title': 'Nhắc uống thuốc',
        'icon': Icons.medication,
        'color': AppColors.medical500
      },
      {
        'title': 'Chỉ số sinh tồn',
        'icon': Icons.monitor_heart,
        'color': Colors.redAccent
      },
      {
        'title': 'Thanh toán',
        'icon': Icons.receipt_long,
        'color': Colors.blueAccent
      },
      {
        'title': 'Hỏi đáp BS',
        'icon': Icons.forum,
        'color': Colors.purpleAccent
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final item = services[index];
        return Column(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                // Đã xóa dấu \ thừa ở dòng bên dưới
                color: (item['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              // Sử dụng Icon chuẩn của Flutter
              child: Icon(item['icon'] as IconData,
                  color: item['color'] as Color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(item['title'] as String,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        );
      },
    );
  }
}
