import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../screens/billing_screen.dart';
import '../screens/medical_records_screen.dart';
import '../screens/test_results_screen.dart';

class QuickServicesWidget extends StatelessWidget {
  final Map<String, dynamic>? vitals;

  const QuickServicesWidget({super.key, this.vitals});

  void _showVitalsSheet(BuildContext context) {
    final v = vitals ?? {};
    final items = [
      {'label': 'Mạch', 'value': v['mach'] ?? 'Chưa đo', 'icon': Icons.favorite, 'color': Colors.redAccent},
      {'label': 'Huyết áp', 'value': v['huyet_ap'] ?? 'Chưa đo', 'icon': Icons.speed, 'color': Colors.blueAccent},
      {'label': 'Nhiệt độ', 'value': v['nhiet_do'] ?? 'Chưa đo', 'icon': Icons.thermostat, 'color': Colors.orange},
      {'label': 'SpO2', 'value': v['spo2'] ?? 'Chưa đo', 'icon': Icons.air, 'color': AppColors.medical600},
      {'label': 'Nhịp thở', 'value': v['nhip_tho'] ?? 'Chưa đo', 'icon': Icons.waves, 'color': Colors.teal},
      {'label': 'Chiều cao', 'value': v['chieu_cao'] ?? 'Chưa đo', 'icon': Icons.height, 'color': Colors.indigo},
      {'label': 'Cân nặng', 'value': v['can_nang'] ?? 'Chưa đo', 'icon': Icons.monitor_weight_outlined, 'color': Colors.purple},
      {'label': 'Chỉ số BMI', 'value': v['bmi'] ?? 'Chưa đo', 'icon': Icons.analytics_outlined, 'color': AppColors.medical700},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chỉ số sinh tồn gần nhất (SQL Server)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate800),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (_, idx) {
                final it = items[idx];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    children: [
                      Icon(it['icon'] as IconData, color: it['color'] as Color, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it['label'] as String,
                              style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                            ),
                            Text(
                              it['value'].toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.slate800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = [
      {
        'title': 'Đơn thuốc',
        'icon': Icons.medication,
        'color': AppColors.medical500,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MedicalRecordsScreen()),
            ),
      },
      {
        'title': 'Chỉ số sinh tồn',
        'icon': Icons.monitor_heart,
        'color': Colors.redAccent,
        'onTap': () => _showVitalsSheet(context),
      },
      {
        'title': 'Thanh toán',
        'icon': Icons.receipt_long,
        'color': Colors.blueAccent,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BillingScreen()),
            ),
      },
      {
        'title': 'Xét nghiệm',
        'icon': Icons.biotech,
        'color': Colors.purpleAccent,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TestResultsScreen()),
            ),
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
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: item['onTap'] as VoidCallback,
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: item['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['title'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }
}
