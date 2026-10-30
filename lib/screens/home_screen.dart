import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import '../widgets/header_widget.dart';
import '../widgets/quick_services_widget.dart';
import '../widgets/upcoming_appointment_widget.dart';
import '../widgets/vip_card_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PatientApiService _api = PatientApiService();
  String? _loadedToken;
  Map<String, dynamic>? _dashboardData;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<AuthViewModel>().currentUser;
    if (user?.token != _loadedToken) {
      _loadedToken = user?.token;
      if (_loadedToken != null && _loadedToken!.isNotEmpty) {
        _fetchDashboard(_loadedToken!);
      } else {
        setState(() {
          _dashboardData = null;
          _error = null;
        });
      }
    }
  }

  Future<void> _fetchDashboard(String token) async {
    try {
      final data = await _api.getDashboard(token);
      if (!mounted) return;
      setState(() {
        _dashboardData = data;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _showAllAppointmentsDialog() async {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để xem danh sách lịch hẹn.')),
      );
      return;
    }
    try {
      final appts = await _api.getAppointments(user.token);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tất cả lịch hẹn khám (${appts.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate800),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: appts.isEmpty
                      ? const Center(child: Text('Bạn chưa có lịch hẹn nào.'))
                      : ListView.separated(
                          controller: controller,
                          itemCount: appts.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (_, idx) {
                            final a = appts[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: AppColors.medical50,
                                child: const Icon(Icons.event_note, color: AppColors.medical600),
                              ),
                              title: Text(
                                '${a['khoa'] ?? 'Chuyên khoa'} • ${a['ngay_hen'] ?? ''} (${a['gio_hen_short'] ?? ''})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                'BS: ${(a['bac_si'] != null && a['bac_si'].toString().isNotEmpty) ? a['bac_si'] : 'Phòng khám sắp xếp'}\nMã: ${a['ma_hen'] ?? ''} • Trạng thái: ${a['trang_thai'] ?? ''}',
                              ),
                              isThreeLine: true,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final patientMap = _dashboardData?['patient'] is Map
        ? Map<String, dynamic>.from(_dashboardData!['patient'] as Map)
        : null;
    final vitalsMap = patientMap?['vitals'] is Map
        ? Map<String, dynamic>.from(patientMap!['vitals'] as Map)
        : null;
    final upcomingMap = _dashboardData?['upcoming_appointment'] is Map
        ? Map<String, dynamic>.from(_dashboardData!['upcoming_appointment'] as Map)
        : null;
    final unreadNotifs = (_dashboardData?['unread_notifications'] as int?) ?? 0;

    return Column(
      children: [
        HeaderWidget(
          unreadCount: unreadNotifs,
          onRefresh: () {
            if (user != null) _fetchDashboard(user.token);
          },
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (user != null) {
                await _fetchDashboard(user.token);
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                      ),
                    ),
                  VipCardWidget(
                    bhyt: patientMap?['bhyt']?.toString(),
                    nhomMau: patientMap?['nhom_mau']?.toString(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tiện ích sức khỏe',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  QuickServicesWidget(vitals: vitalsMap),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lịch khám sắp tới',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: _showAllAppointmentsDialog,
                        child: const Text('Xem tất cả'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  UpcomingAppointmentWidget(
                    appointment: upcomingMap,
                    onChanged: () {
                      if (user != null) _fetchDashboard(user.token);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
