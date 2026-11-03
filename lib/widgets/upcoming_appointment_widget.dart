import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../screens/appointment_screen.dart';

class UpcomingAppointmentWidget extends StatelessWidget {
  final Map<String, dynamic>? appointment;
  final VoidCallback? onChanged;

  const UpcomingAppointmentWidget({
    super.key,
    this.appointment,
    this.onChanged,
  });

  void _showDetailModal(BuildContext context, Map<String, dynamic> appt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Chi tiết lịch hẹn ${(appt['ma_lich_hen'] ?? appt['ma_hen']) ?? ''}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailLine('Chuyên khoa:', appt['khoa']?.toString() ?? ''),
            _detailLine('Bác sĩ:', (appt['bac_si'] != null && appt['bac_si'].toString().isNotEmpty) ? appt['bac_si'].toString() : 'Phòng khám điều phối'),
            _detailLine('Phòng khám:', appt['ten_phong']?.toString() ?? 'Quầy tiếp đón phân bổ'),
            _detailLine('Ngày hẹn:', appt['ngay_hen']?.toString() ?? ''),
            _detailLine('Giờ khám:', (appt['gio_hen_short'] ?? appt['gio_hen'])?.toString() ?? ''),
            _detailLine('Trạng thái:', appt['trang_thai']?.toString() ?? ''),
            _detailLine('Lý do khám:', (appt['ly_do_kham'] ?? appt['ly_do'])?.toString() ?? ''),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(label, style: const TextStyle(color: AppColors.slate500, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showManageSheet(BuildContext context, Map<String, dynamic> appt) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentScreen(initialTab: 1)));
    if (context.mounted) onChanged?.call();
  }
  @override
  Widget build(BuildContext context) {
    if (appointment == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Column(
          children: [
            const Icon(Icons.event_available_outlined, color: AppColors.medical600, size: 32),
            const SizedBox(height: 8),
            const Text(
              'Bạn chưa có lịch khám sắp tới',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Đặt lịch trực tuyến để được ưu tiên tiếp đón nhanh chóng.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.slate500),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.medical600),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppointmentScreen()),
                );
                onChanged?.call();
              },
              icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
              label: const Text('Đặt lịch khám ngay', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final appt = appointment!;
    final rawDate = (appt['ngay_hen'] ?? '').toString();
    final parts = rawDate.split('-');
    final monthStr = parts.length >= 2 ? 'Th ${int.tryParse(parts[1]) ?? parts[1]}' : 'Lịch';
    final dayStr = parts.length >= 3 ? parts[2] : '--';
    final deptName = (appt['khoa'] ?? 'Khám chuyên khoa').toString();
    final docName = (appt['bac_si'] != null && appt['bac_si'].toString().isNotEmpty)
        ? appt['bac_si'].toString()
        : 'Bác sĩ chuyên khoa';
    final timeStr = ((appt['gio_hen_short'] ?? appt['gio_hen']) ?? '').toString();
    final statusStr = (appt['trang_thai'] ?? 'Chờ xác nhận').toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.medical500,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      monthStr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dayStr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deptName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$docName • $timeStr',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.medical50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusStr,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.medical700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showManageSheet(context, appt),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Đổi / Hủy lịch', style: TextStyle(color: AppColors.slate700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showDetailModal(context, appt),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.medical600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Chi tiết', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
