import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import '../services/sound_service.dart';
import 'home_screen.dart';
import 'appointment_screen.dart';
import 'medical_records_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final PatientApiService _apiService = PatientApiService();
  int _currentIndex = 0;
  int _refreshKey = 0;
  String? _lastToken;

  Timer? _pollTimer;
  Set<int> _knownNotificationIds = {};
  bool _initialFetchDone = false;
  Map<String, dynamic>? _activeToast;
  Timer? _toastDismissTimer;

  @override
  void initState() {
    super.initState();
    // Tự động kiểm tra thông báo mới mỗi 5 giây
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_lastToken != null && _lastToken!.isNotEmpty && mounted) {
        _checkNewNotifications(_lastToken!);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _toastDismissTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context.watch<AuthViewModel>().currentUser?.token;
    if (token != _lastToken) {
      _lastToken = token;
      _initialFetchDone = false;
      _knownNotificationIds.clear();
      _dismissToast();
      if (token != null && token.isNotEmpty) {
        _checkNewNotifications(token);
      }
    }
  }

  Future<void> _checkNewNotifications(String token) async {
    try {
      final list = await _apiService.getNotifications(token);
      if (!mounted) return;

      final currentIds = <int>{};
      for (final n in list) {
        final id = n['id'];
        if (id is int) currentIds.add(id);
      }

      if (!_initialFetchDone) {
        _knownNotificationIds = currentIds;
        _initialFetchDone = true;
        return;
      }

      // Tìm thông báo mới chưa từng thấy trước đó
      final newItems = list.where((n) {
        final id = n['id'];
        final isUnread = n['da_xem'] != true && n['da_doc'] != 1;
        return id is int && !_knownNotificationIds.contains(id) && isUnread;
      }).toList();

      if (newItems.isNotEmpty) {
        final newest = newItems.first;
        _knownNotificationIds.addAll(currentIds);
        _showInAppToast(newest);
      } else {
        _knownNotificationIds.addAll(currentIds);
      }
    } catch (_) {}
  }

  void _showInAppToast(Map<String, dynamic> notif) {
    _toastDismissTimer?.cancel();
    SoundService.playNotificationSound();
    setState(() {
      _activeToast = notif;
      _refreshKey++; // Làm mới dữ liệu các tab (ví dụ tab lịch khám nhận trạng thái mới)
    });
    // Tự động đóng thông báo nổi sau 6 giây
    _toastDismissTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) {
        _dismissToast();
      }
    });
  }

  void _dismissToast() {
    _toastDismissTimer?.cancel();
    if (_activeToast != null) {
      setState(() => _activeToast = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final pages = [
      HomeScreen(key: ValueKey('home_$_refreshKey')),
      AppointmentScreen(key: ValueKey('appt_$_refreshKey')),
      MedicalRecordsScreen(key: ValueKey('records_$_refreshKey')),
      ProfileScreen(user: authViewModel.currentUser),
    ];

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                _refreshKey++;
              });
            },
            selectedItemColor: AppColors.medical600,
            unselectedItemColor: AppColors.slate400,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                  icon: FaIcon(FontAwesomeIcons.house, size: 20),
                  label: 'Trang chủ'),
              BottomNavigationBarItem(
                  icon: FaIcon(FontAwesomeIcons.calendarPlus, size: 20),
                  label: 'Đặt lịch'),
              BottomNavigationBarItem(
                  icon: FaIcon(FontAwesomeIcons.fileMedical, size: 20),
                  label: 'Hồ sơ'),
              BottomNavigationBarItem(
                  icon: FaIcon(FontAwesomeIcons.userGear, size: 20),
                  label: 'Tài khoản'),
            ],
          ),
        ),

        // KHUNG THÔNG BÁO NỔI (IN-APP NOTIFICATION BANNER Y HỆT BÊN WEB)
        if (_activeToast != null)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      _dismissToast();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2825), // Nền xanh rêu đậm sang trọng như bên Web
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF134E4A), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon Chuông viền sáng
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F766E).withOpacity(0.4),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF2DD4BF),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Center(
                                      child: FaIcon(
                                        FontAwesomeIcons.solidBell,
                                        color: Colors.amber,
                                        size: 17,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Nội dung thông báo
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                (_activeToast!['tieu_de'] ?? 'Thông báo hệ thống').toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2DD4BF).withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'Mới',
                                                style: TextStyle(
                                                  color: Color(0xFF2DD4BF),
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          (_activeToast!['noi_dung'] ?? '').toString(),
                                          style: const TextStyle(
                                            color: Color(0xFFCBD5E1),
                                            fontSize: 11.5,
                                            height: 1.35,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        const Row(
                                          children: [
                                            Icon(Icons.touch_app, size: 12, color: Color(0xFF2DD4BF)),
                                            SizedBox(width: 4),
                                            Text(
                                              'Chạm để xem chi tiết thông báo',
                                              style: TextStyle(
                                                color: Color(0xFF2DD4BF),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Nút đóng dấu X
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                                    onPressed: _dismissToast,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                            // Thanh hiệu ứng chuyển màu xanh ở chân thông báo
                            Container(
                              height: 3,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF2DD4BF),
                                    Color(0xFF0F766E),
                                    Color(0xFF0D9488),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
