import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:appmobi/core/app_colors.dart';
import 'package:appmobi/core/app_animations.dart';
import 'package:appmobi/services/auth_service.dart';
import 'package:appmobi/services/patient_api_service.dart';
import 'package:appmobi/screens/home_screen.dart';
import 'package:appmobi/screens/appointment_screen.dart';
import 'package:appmobi/screens/medical_records_screen.dart';
import 'package:appmobi/screens/profile_screen.dart';
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
      GlobalNotificationBanner.dismiss();
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
    if (!mounted) return;
    final title = (notif['tieu_de'] ?? 'Thông báo mới').toString();
    final body = (notif['noi_dung'] ?? '').toString();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        backgroundColor: const Color(0xFF0D2825),
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF134E4A), width: 1.2),
        ),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.4),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2DD4BF), width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.notifications_active_rounded,
                    color: Color(0xFF2DD4BF), size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: Colors.white,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFCCFBF1),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    setState(() {
      _refreshKey++; // Làm mới dữ liệu các tab (ví dụ tab lịch khám nhận trạng thái mới)
    });
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

    return Scaffold(
      body: SafeArea(
        child: AppTabTransition(
          switchKey: ValueKey<int>(_currentIndex),
          duration: const Duration(milliseconds: 380),
          child: pages[_currentIndex],
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
    );
  }
}
