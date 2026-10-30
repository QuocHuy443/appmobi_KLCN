import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
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
        title: Text('Chi tiết lịch hẹn ${appt['ma_hen'] ?? ''}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailLine('Chuyên khoa:', appt['khoa']?.toString() ?? ''),
            _detailLine('Bác sĩ:', (appt['bac_si'] != null && appt['bac_si'].toString().isNotEmpty) ? appt['bac_si'].toString() : 'Phòng khám điều phối'),
            _detailLine('Phòng khám:', appt['ten_phong']?.toString() ?? 'Quầy tiếp đón phân bổ'),
            _detailLine('Ngày hẹn:', appt['ngay_hen']?.toString() ?? ''),
            _detailLine('Giờ khám:', appt['gio_hen_short']?.toString() ?? ''),
            _detailLine('Trạng thái:', appt['trang_thai']?.toString() ?? ''),
            _detailLine('Lý do khám:', appt['ly_do']?.toString() ?? ''),
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

  void _showManageSheet(BuildContext context, Map<String, dynamic> appt) {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) return;
    final api = PatientApiService();
    final apptId = appt['id'] as int?;
    if (apptId == null) return;

    DateTime selectedDate = DateTime.tryParse(appt['ngay_hen']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 1));
    String selectedTime = appt['gio_hen_short']?.toString() ?? '08:30';
    final times = ['07:30', '08:00', '08:30', '09:00', '09:30', '10:00', '10:30', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đổi / Hủy lịch hẹn (${appt['ma_hen'] ?? ''})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate800),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month, color: AppColors.medical600),
                  title: Text('Ngày hẹn mới: $dateStr'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate.isBefore(DateTime.now()) ? DateTime.now() : selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setSheetState(() => selectedDate = picked);
                      }
                    },
                    child: const Text('Chọn ngày'),
                  ),
                ),
                const Text('Chọn giờ hẹn mới:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: times.map((t) {
                    final sel = t == selectedTime;
                    return ChoiceChip(
                      label: Text(t),
                      selected: sel,
                      onSelected: (_) => setSheetState(() => selectedTime = t),
                      selectedColor: AppColors.medical100,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                        label: const Text('Hủy lịch hẹn', style: TextStyle(color: Colors.red)),
                        onPressed: () async {
                          try {
                            final msg = await api.cancelAppointment(
                              token: user.token,
                              appointmentId: apptId,
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                            onChanged?.call();
                          } catch (e) {
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.medical600),
                        icon: const Icon(Icons.save_outlined, color: Colors.white),
                        label: const Text('Lưu đổi lịch', style: TextStyle(color: Colors.white)),
                        onPressed: () async {
                          try {
                            final msg = await api.rescheduleAppointment(
                              token: user.token,
                              appointmentId: apptId,
                              ngayHen: dateStr,
                              gioHen: selectedTime,
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                            onChanged?.call();
                          } catch (e) {
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
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
    final timeStr = (appt['gio_hen_short'] ?? '08:30').toString();
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
