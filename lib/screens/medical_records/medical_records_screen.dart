import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/notification_badge_widget.dart';
import '../notifications/notifications_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MedicalRecordsScreen extends StatelessWidget {
  const MedicalRecordsScreen({super.key});

  final List<Map<String, dynamic>> _records = const [
    {
      'date': '22/09/2026',
      'doctor': 'PGS.TS Trần Văn A (Tim mạch)',
      'diagnosis': 'Tăng huyết áp vô căn',
      'status': 'Đã hoàn thành',
      'statusColor': AppColors.medical600,
      'prescription': '1. Amlodipine 5mg (30 viên)\n2. Losartan 50mg (30 viên)',
      'note': 'Hạn chế ăn mặn, tập thể dục đều đặn 30 phút mỗi ngày.',
    },
    {
      'date': '15/08/2026',
      'doctor': 'BS.CKII Nguyễn Thị B (Nhi khoa)',
      'diagnosis': 'Viêm họng cấp',
      'status': 'Đã hoàn thành',
      'statusColor': AppColors.medical600,
      'prescription': '1. Amoxicillin 500mg (20 viên)\n2. Paracetamol 500mg (10 viên)',
      'note': 'Uống nhiều nước ấm, súc họng nước muối sinh lý.',
    },
    {
      'date': '01/07/2026',
      'doctor': 'ThS.BS Lê Văn C (Nội khoa)',
      'diagnosis': 'Viêm loét dạ dày tá tràng',
      'status': 'Đang điều trị',
      'statusColor': Colors.amber,
      'prescription': '1. Omeprazole 20mg (14 viên)\n2. Phosphalugel (14 gói)',
      'note': 'Ăn đúng giờ, tránh đồ cay nóng và stress.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ bệnh án'),
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
      body: Column(
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('6 tháng gần đây', style: TextStyle(color: AppColors.slate700)),
                        Icon(Icons.arrow_drop_down, color: AppColors.slate700),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tất cả cơ sở', style: TextStyle(color: AppColors.slate700)),
                        Icon(Icons.arrow_drop_down, color: AppColors.slate700),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Records List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _records.length,
              itemBuilder: (context, index) {
                final record = _records[index];
                return GestureDetector(
                  onTap: () => _showRecordDetails(context, record),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.medical50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const FaIcon(
                                FontAwesomeIcons.fileMedical,
                                color: AppColors.medical600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 60,
                              width: 2,
                              color: AppColors.slate200,
                            ) // Timeline effect
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    record['date'],
                                    style: const TextStyle(
                                      color: AppColors.slate500,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (record['statusColor'] as Color).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      record['status'],
                                      style: TextStyle(
                                        color: record['statusColor'],
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                record['diagnosis'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                record['doctor'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.slate600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Xem chi tiết >',
                                style: TextStyle(
                                  color: AppColors.medical600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              )
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

  void _showRecordDetails(BuildContext context, Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.slate300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Chi tiết khám bệnh',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Ngày khám', record['date']),
              _buildDetailRow('Chẩn đoán', record['diagnosis'], isBold: true),
              _buildDetailRow('Bác sĩ', record['doctor']),
              const Divider(height: 32),
              const Text(
                'Đơn thuốc',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  record['prescription'],
                  style: const TextStyle(color: AppColors.slate700, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Lời dặn của bác sĩ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.medical50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.medical100),
                ),
                child: Text(
                  record['note'],
                  style: const TextStyle(color: AppColors.medical700, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.slate500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: AppColors.slate800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}