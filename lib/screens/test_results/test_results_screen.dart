import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/notification_badge_widget.dart';
import '../notifications/notifications_screen.dart';

class TestResultsScreen extends StatelessWidget {
  const TestResultsScreen({super.key});

  final Map<String, List<Map<String, dynamic>>> _resultsByDate = const {
    '22/09/2026': [
      {'name': 'Glucose', 'result': 6.5, 'unit': 'mmol/L', 'ref': '3.9 - 6.4', 'isAbnormal': true},
      {'name': 'Cholesterol', 'result': 5.2, 'unit': 'mmol/L', 'ref': '< 5.1', 'isAbnormal': true},
      {'name': 'Triglyceride', 'result': 1.5, 'unit': 'mmol/L', 'ref': '< 1.7', 'isAbnormal': false},
    ],
    '15/08/2026': [
      {'name': 'Hồng cầu (RBC)', 'result': 4.5, 'unit': 'T/L', 'ref': '4.0 - 5.8', 'isAbnormal': false},
      {'name': 'Bạch cầu (WBC)', 'result': 7.2, 'unit': 'G/L', 'ref': '4.0 - 10.0', 'isAbnormal': false},
      {'name': 'Tiểu cầu (PLT)', 'result': 250, 'unit': 'G/L', 'ref': '150 - 400', 'isAbnormal': false},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả xét nghiệm'),
        actions: [
          NotificationBadgeWidget(
            count: 0,
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _resultsByDate.length,
        itemBuilder: (context, index) {
          final date = _resultsByDate.keys.elementAt(index);
          final results = _resultsByDate[date]!;
          return _buildDateGroup(date, results);
        },
      ),
    );
  }

  Widget _buildDateGroup(String date, List<Map<String, dynamic>> results) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate200.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Date & Download button)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.medical50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.medical600),
                    const SizedBox(width: 8),
                    Text(
                      date,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.medical700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Tải PDF'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.medical600,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
              ],
            ),
          ),
          
          // Table Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text('Tên chỉ số', style: TextStyle(color: AppColors.slate500, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 1,
                  child: Text('Kết quả', textAlign: TextAlign.center, style: TextStyle(color: AppColors.slate500, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 1,
                  child: Text('Tham chiếu', textAlign: TextAlign.right, style: TextStyle(color: AppColors.slate500, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.slate200),
          
          // Table Rows
          ...results.map((result) {
            final isAbnormal = result['isAbnormal'] as bool;
            final resultColor = isAbnormal ? Colors.red : AppColors.slate800;
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.slate100)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result['name'],
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate800),
                        ),
                        if (isAbnormal)
                          const Text(
                            'Vượt khoảng tham chiếu',
                            style: TextStyle(color: Colors.orange, fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Text(
                          result['result'].toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: resultColor,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          result['unit'],
                          style: const TextStyle(color: AppColors.slate400, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      result['ref'],
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: AppColors.slate600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
