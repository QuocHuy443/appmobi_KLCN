import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:appmobi/core/app_colors.dart';
import 'package:appmobi/services/auth_service.dart';
import 'package:appmobi/services/patient_api_service.dart';
import 'package:appmobi/services/sound_service.dart';
import 'package:appmobi/screens/home_screen.dart';
import 'package:appmobi/screens/appointment_screen.dart';
import 'package:appmobi/screens/medical_records_screen.dart';
import 'package:appmobi/screens/profile_screen.dart';
import 'package:appmobi/screens/notifications_screen.dart';
import 'personal_profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key, this.apiService});

  final PatientApiService? apiService;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late final PatientApiService _apiService =
      widget.apiService ?? PatientApiService();
  int _currentIndex = 0;
  int _refreshKey = 0;
  String? _lastToken;

  Timer? _pollTimer;
  final Set<String> _knownNotificationIds = {};
  bool _pollInFlight = false;
  int _sessionGeneration = 0;
  bool _initialFetchDone = false;
  Map<String, dynamic>? _activeToast;
  Timer? _toastDismissTimer;

  @override
  void initState() {
    super.initState();
    PatientApiService.dataRevision.addListener(_dataChanged);
  }

  void _dataChanged() {
    if (mounted) setState(() => _refreshKey++);
  }

  @override
  void dispose() {
    PatientApiService.dataRevision.removeListener(_dataChanged);
    _pollTimer?.cancel();
    _toastDismissTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<AuthViewModel>().currentUser;
    final token = user?.profileComplete == true ? user?.token : null;
    if (token != _lastToken) {
      _lastToken = token;
      final generation = ++_sessionGeneration;
      _pollTimer?.cancel();
      _pollTimer = null;
      _toastDismissTimer?.cancel();
      _activeToast = null;
      _initialFetchDone = false;
      _knownNotificationIds.clear();

      if (token != null && token.isNotEmpty) {
        _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          _checkNewNotifications(token);
        });
      }
      scheduleMicrotask(() {
        if (!mounted || generation != _sessionGeneration) return;
        PatientApiService.resetNotifications(token);
        if (token != null && token.isNotEmpty) _checkNewNotifications(token);
      });
    }
  }

  Future<void> _checkNewNotifications(String token) async {
    if (_pollInFlight ||
        !mounted ||
        token != _lastToken ||
        context.read<AuthViewModel>().currentUser?.token != token) {
      return;
    }
    final generation = _sessionGeneration;
    _pollInFlight = true;
    try {
      final list = await _apiService.getNotifications(token);
      if (!mounted ||
          generation != _sessionGeneration ||
          token != _lastToken ||
          context.read<AuthViewModel>().currentUser?.token != token) {
        return;
      }

      final currentIds = <String>{};
      for (final n in list) {
        final id = n['id'];
        if (id != null) currentIds.add(id.toString());
      }

      if (!_initialFetchDone) {
        _knownNotificationIds.addAll(currentIds);
        _initialFetchDone = true;
        return;
      }

      // Tìm thông báo mới chưa từng thấy trước đó
      final newItems = list.where((n) {
        final id = n['id'];
        final isUnread = !PatientApiService.isNotificationRead(n);
        return id != null &&
            !_knownNotificationIds.contains(id.toString()) &&
            isUnread;
      }).toList();

      if (newItems.isNotEmpty) {
        final newest = newItems.first;
        _knownNotificationIds.addAll(currentIds);
        _showInAppToast(newest);
      } else {
        _knownNotificationIds.addAll(currentIds);
      }
    } catch (_) {
      // Retry on the next poll; failed API requests never produce notifications.
    } finally {
      _pollInFlight = false;
    }
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
    if (authViewModel.currentUser?.profileComplete == false) {
      return CompleteProfileScreen(apiService: widget.apiService);
    }
    final pages = [
      HomeScreen(refreshVersion: _refreshKey),
      AppointmentScreen(refreshVersion: _refreshKey),
      MedicalRecordsScreen(refreshVersion: _refreshKey),
      ProfileScreen(user: authViewModel.currentUser, refreshVersion: _refreshKey),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        color: const Color(
                            0xFF0D2825), // Nền xanh rêu đậm sang trọng như bên Web
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: const Color(0xFF134E4A), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
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
                                      color: const Color(0xFF0F766E)
                                          .withValues(alpha: 0.4),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                (_activeToast!['tieu_de'] ??
                                                        'Thông báo hệ thống')
                                                    .toString(),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2DD4BF)
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(6),
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
                                          (_activeToast!['noi_dung'] ?? '')
                                              .toString(),
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
                                            Icon(Icons.touch_app,
                                                size: 12,
                                                color: Color(0xFF2DD4BF)),
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
                                    icon: const Icon(Icons.close,
                                        color: Colors.white54, size: 18),
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
