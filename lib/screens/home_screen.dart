import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/patient_format.dart';
import '../core/app_animations.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import '../widgets/header_widget.dart';
import '../widgets/upcoming_appointment_widget.dart';
import 'appointment_screen.dart';
import 'articles_screen.dart';
import 'pricing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.refreshVersion = 0});

  final int refreshVersion;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PatientApiService _api = PatientApiService();
  String? _loadedToken;
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _publicHomeData;
  bool _loadingPublic = true;
  String? _publicError;
  String? _error;

  int _selectedTabIndex = 0;
  int? _selectedDepartmentFilterId;
  String? _selectedCategoryFilter;
  final TextEditingController _doctorSearchController = TextEditingController();

  final List<Map<String, dynamic>> _tabs = const [
    {'title': 'Tổng quan', 'icon': Icons.local_hospital_outlined},
    {'title': 'Chuyên khoa', 'icon': Icons.medical_services_outlined},
    {'title': 'Đội ngũ Bác sĩ', 'icon': Icons.people_outline},
    {'title': 'Bảng giá viện phí', 'icon': Icons.price_check_rounded},
    {'title': 'Tin tức và Cẩm nang', 'icon': Icons.newspaper_rounded},
    {'title': 'Quy trình khám', 'icon': Icons.checklist_rtl},
  ];

  @override
  void initState() {
    super.initState();
    _fetchPublicHome();
  }

  @override
  void dispose() {
    _doctorSearchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion) {
      _fetchPublicHome();
      final token = context.read<AuthViewModel>().currentUser?.token;
      if (token != null && token.isNotEmpty) {
        _fetchDashboard(token);
      }
    }
  }

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

  Future<void> _fetchPublicHome() async {
    if (mounted) {
      setState(() {
        _loadingPublic = true;
      });
    }
    try {
      final data = await _api.getPublicHome();
      if (!mounted) return;
      setState(() {
        _publicHomeData = data;
        _loadingPublic = false;
        _publicError = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadingPublic = false;
          _publicError = 'Không tải được dữ liệu phòng khám. Kiểm tra máy chủ API và thử lại.';
        });
      }
    }
  }

  Future<void> _fetchDashboard(String token) async {
    try {
      final data = await _api.getDashboard(token);
      if (!mounted || token != _loadedToken) return;
      final profile = data['patient'];
      if (profile is Map) {
        context.read<AuthViewModel>().updatePatientProfile(
              token,
              Map<String, dynamic>.from(profile),
            );
      }
      setState(() {
        _dashboardData = data;
        _error = null;
      });
    } catch (e) {
      if (!mounted || token != _loadedToken) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _navigateToAppointment({int? departmentId, int? doctorId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentScreen(
          initialTab: 0,
          initialDepartmentId: departmentId,
          initialDoctorId: doctorId,
        ),
      ),
    );
  }

  Widget _buildHorizontalMenu() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _tabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final tab = _tabs[index];
            final isSelected = _selectedTabIndex == index;
            return AppScaleTap(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: AppAnimations.fast,
                curve: AppAnimations.modernCurve,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.medical600 : AppColors.slate100,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? AppColors.medical700 : AppColors.slate200,
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.medical600.withAlpha(50),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 15,
                      color: isSelected ? Colors.white : AppColors.slate600,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      tab['title'] as String,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.slate700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverviewTab({
    required List<Map<String, dynamic>> banners,
    required List<Map<String, dynamic>> departments,
    required List<Map<String, dynamic>> doctors,
    required List<Map<String, dynamic>> articles,
    required List<Map<String, dynamic>> feedbacks,
    required Map<String, dynamic>? upcomingMap,
  }) {
    final activeBanner = banners.isNotEmpty ? banners.first : null;
    final title = (activeBanner?['tieu_de'] ??
            'Hệ thống Y tế Đa khoa Quốc tế H2T Healthcare')
        .toString();
    final desc = (activeBanner?['mo_ta'] ??
            'Đặt lịch khám theo ca trực, tra cứu bảng giá niêm yết công khai và cập nhật cẩm nang sức khỏe chính thống 24/7.')
        .toString();

    final user = context.watch<AuthViewModel>().currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSlideFade(
          delay: const Duration(milliseconds: 40),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.medical200),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.medical50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.hospital,
                              size: 11,
                              color: AppColors.medical600,
                            ),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'CỔNG THÔNG TIN PHÒNG KHÁM H2T',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.medical700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '07:00 - 20:30',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.slate600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppScaleTap(
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = 3;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.medical600),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.price_check_rounded, size: 17, color: AppColors.medical600),
                                SizedBox(width: 6),
                                Text(
                                  'Tra cứu Bảng giá',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.medical600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppScaleTap(
                        onTap: () => _navigateToAppointment(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.medical600,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.medical600.withAlpha(60),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_month, size: 17, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Đặt lịch khám',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppSlideFade(
          delay: const Duration(milliseconds: 120),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.medical50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user,
                          color: AppColors.medical600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '100% Bác sĩ',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate800,
                        ),
                      ),
                      const Text(
                        'Chuyên khoa',
                        style: TextStyle(fontSize: 10, color: AppColors.slate500),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.slate200),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.medical_information,
                          color: Colors.blueAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Chuẩn Bộ Y Tế',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate800,
                        ),
                      ),
                      const Text(
                        'Thiết bị y tế',
                        style: TextStyle(fontSize: 10, color: AppColors.slate500),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.slate200),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFECFDF5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.credit_card,
                          color: AppColors.medical600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Áp dụng BHYT',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate800,
                        ),
                      ),
                      const Text(
                        'Đúng tuyến',
                        style: TextStyle(fontSize: 10, color: AppColors.slate500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        AppSlideFade(
          delay: const Duration(milliseconds: 190),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dịch vụ khám chữa bệnh',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800,
                ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  AppScaleTap(
                    onTap: () => _navigateToAppointment(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.medical50,
                            radius: 17,
                            child: Icon(Icons.calendar_month,
                                color: AppColors.medical600, size: 17),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Đặt lịch khám',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11.5, fontWeight: FontWeight.bold)),
                                Text('Chọn bác sĩ và giờ',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 10, color: AppColors.slate500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppScaleTap(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 3;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Color(0xFFECFDF5),
                            radius: 17,
                            child: Icon(Icons.price_check_rounded,
                                color: AppColors.medical600, size: 17),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Bảng giá viện phí',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11.5, fontWeight: FontWeight.bold)),
                                Text('Niêm yết và BHYT',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 10, color: AppColors.slate500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppScaleTap(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Color(0xFFEFF6FF),
                            radius: 17,
                            child: Icon(Icons.local_hospital_outlined,
                                color: Colors.blueAccent, size: 17),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Chuyên khoa',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11.5, fontWeight: FontWeight.bold)),
                                Text('Khoa khám điều trị',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 10, color: AppColors.slate500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppScaleTap(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 5;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Color(0xFFFFFBEB),
                            radius: 17,
                            child: Icon(Icons.checklist_rtl,
                                color: Colors.amber, size: 17),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quy trình khám',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11.5, fontWeight: FontWeight.bold)),
                                Text('4 bước chuẩn y khoa',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 10, color: AppColors.slate500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (upcomingMap != null) ...[
          const SizedBox(height: 18),
          AppSlideFade(
            delay: const Duration(milliseconds: 260),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lịch khám sắp tới của bạn',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate800,
                  ),
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
        ],
        const SizedBox(height: 18),
        AppSlideFade(
          delay: const Duration(milliseconds: 320),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Chuyên khoa nổi bật',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedTabIndex = 1),
                    child: const Text('Xem tất cả'),
                  ),
                ],
              ),
              if (departments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Text(
                    _loadingPublic
                        ? 'Đang tải danh sách chuyên khoa...'
                        : 'Chưa có chuyên khoa hoạt động.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.slate500,
                    ),
                  ),
                )
              else
                ...departments.take(3).map((dep) {
                  final depId = (dep['id'] as num?)?.toInt();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.medical50,
                          child: Icon(Icons.health_and_safety,
                              color: AppColors.medical600),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${dep['ten_khoa']}',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate800,
                                ),
                              ),
                              Text(
                                '${dep['mo_ta'] ?? 'Khoa khám chữa bệnh chuyên sâu'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _navigateToAppointment(departmentId: depId),
                          child: const Text('Đặt khám'),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppSlideFade(
          delay: const Duration(milliseconds: 350),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Đội ngũ bác sĩ chuyên khoa',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedTabIndex = 2),
                    child: const Text('Xem tất cả'),
                  ),
                ],
              ),
              if (doctors.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Text(
                    _loadingPublic
                        ? 'Đang tải danh sách bác sĩ...'
                        : 'Chưa có thông tin bác sĩ.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.slate500,
                    ),
                  ),
                )
              else
                ...doctors.take(3).map((doc) {
                  final docId = (doc['id'] as num?)?.toInt();
                  final depId = (doc['chuyen_khoa_id'] as num?)?.toInt();
                  final displayName =
                      (doc['ten_hien_thi'] ?? doc['ho_ten'] ?? 'Bác sĩ chuyên khoa')
                          .toString();
                  final depName =
                      (doc['ten_khoa'] ?? doc['chuyen_khoa'] ?? 'Đa khoa')
                          .toString();
                  final avatarUrl = PatientApiService.mediaUrl(doc['avatar']) ??
                      PatientApiService.avatarUrl(doc['avatar']);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.medical100,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? const Icon(Icons.person,
                                  color: AppColors.medical700)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate800,
                                ),
                              ),
                              Text(
                                'Chuyên khoa: $depName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _navigateToAppointment(
                            departmentId: depId,
                            doctorId: docId,
                          ),
                          child: const Text('Đặt khám'),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppSlideFade(
          delay: const Duration(milliseconds: 380),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Tin tức và Cẩm nang mới',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedTabIndex = 4),
                    child: const Text('Xem tất cả'),
                  ),
                ],
              ),
              if (articles.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Text(
                    _loadingPublic
                        ? 'Đang tải tin tức và cẩm nang y tế...'
                        : 'Chưa có bài viết y khoa mới.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.slate500,
                    ),
                  ),
                )
              else
                ...articles.take(2).map((art) {
                  final imgUrl = PatientApiService.mediaUrl(art['image']);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArticleDetailScreen(
                              slug: (art['slug'] ?? '').toString(),
                              initialArticle: art,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 58,
                              height: 58,
                              color: AppColors.medical50,
                              child: imgUrl != null
                                  ? Image.network(
                                      imgUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.article_outlined,
                                          color: AppColors.medical600),
                                    )
                                  : const Icon(Icons.article_outlined,
                                      color: AppColors.medical600),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${art['title'] ?? ''}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.slate800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${art['category_name'] ?? 'Y khoa'} • ${art['published_at'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.slate400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        if (feedbacks.isNotEmpty) ...[
          const SizedBox(height: 14),
          AppSlideFade(
            delay: const Duration(milliseconds: 410),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đánh giá từ bệnh nhân',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate800,
                  ),
                ),
                const SizedBox(height: 8),
                ...feedbacks.take(3).map((fb) {
                  final stars = (fb['diem_danh_gia'] as num?)?.toInt() ?? 5;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${fb['ten_benh_nhan'] ?? 'Bệnh nhân'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate800,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                stars.clamp(1, 5),
                                (_) => const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${fb['noi_dung'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.slate600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

    Widget _buildDepartmentsTab(List<Map<String, dynamic>> departments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Danh mục Chuyên khoa Điều trị',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Phòng khám Đa khoa H2T quy tụ đầy đủ các chuyên khoa mũi nhọn (${departments.length} chuyên khoa), sẵn sàng đáp ứng mọi nhu cầu khám chữa bệnh của người dân.',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.slate600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (departments.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Đang cập nhật danh mục chuyên khoa...'),
            ),
          )
        else
          ...departments.map((dep) {
            final depId = (dep['id'] as num?)?.toInt();
            final fee = dep['gia_kham_mac_dinh'];
            final docCount = dep['so_bac_si'] ?? dep['doctor_count'] ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.medical50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          color: AppColors.medical600,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${dep['ten_khoa']}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.slate800,
                              ),
                            ),
                            Text(
                              'Mã khoa: ${dep['ma_khoa'] ?? 'CHUNG'} • Bác sĩ trực: $docCount',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${dep['mo_ta'] ?? 'Khoa khám chữa bệnh chuyên sâu với trang thiết bị y tế hiện đại và phác đồ điều trị chuẩn Bộ Y tế.'}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.slate600,
                      height: 1.35,
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giá khám tiêu chuẩn:',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.slate400,
                            ),
                          ),
                          Text(
                            fee != null ? patientMoney(fee) : 'Theo quy định',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.medical700,
                            ),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () =>
                            _navigateToAppointment(departmentId: depId),
                        icon: const Icon(Icons.calendar_month, size: 16),
                        label: const Text(
                          'Đặt khám khoa này',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildDoctorsTab(List<Map<String, dynamic>> doctors) {
    final query = _doctorSearchController.text.trim().toLowerCase();
    final filtered = doctors.where((d) {
      if (query.isEmpty) return true;
      final name = (d['ho_ten'] ?? '').toString().toLowerCase();
      final dep = (d['ten_khoa'] ?? d['chuyen_khoa'] ?? '').toString().toLowerCase();
      return name.contains(query) || dep.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Đội ngũ Chuyên gia và Bác sĩ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Các Giáo sư, Tiến sĩ, Bác sĩ Chuyên khoa giàu kinh nghiệm và y đức, tận tình thăm khám và tư vấn cho bệnh nhân.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.slate600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _doctorSearchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên bác sĩ hoặc chuyên khoa...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _doctorSearchController.clear();
                            setState(() {});
                          },
                        ),
                  filled: true,
                  fillColor: AppColors.slate50,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Không tìm thấy bác sĩ phù hợp.'),
            ),
          )
        else
          ...filtered.map((doc) {
            final docId = (doc['id'] as num?)?.toInt();
            final depId = (doc['chuyen_khoa_id'] as num?)?.toInt();
            final name = (doc['ho_ten'] ?? 'Bác sĩ chuyên khoa').toString();
            final degree = (doc['hoc_vi'] ?? doc['hoc_ham_hoc_vi'] ?? 'BS')
                .toString();
            final depName = (doc['ten_khoa'] ?? doc['chuyen_khoa'] ?? 'Đa khoa')
                .toString();
            final exp = doc['kinh_nghiem']?.toString() ?? 'Nhiều năm kinh nghiệm';
            final room = doc['ten_phong']?.toString() ?? 'Phòng khám chuyên khoa';
            final avatarUrl = PatientApiService.mediaUrl(doc['avatar']) ??
                PatientApiService.avatarUrl(doc['avatar']);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.medical100,
                        backgroundImage:
                            avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? const Icon(Icons.person,
                                color: AppColors.medical700, size: 28)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.medical50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                degree,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.medical700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.slate800,
                              ),
                            ),
                            Text(
                              'Khoa: $depName',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.medical600,
                              ),
                            ),
                            Text(
                              '$room • $exp',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 15, color: AppColors.medical600),
                          SizedBox(width: 5),
                          Text(
                            'Sẵn sàng nhận lịch',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.slate600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _navigateToAppointment(
                          departmentId: depId,
                          doctorId: docId,
                        ),
                        icon: const Icon(Icons.calendar_month, size: 16),
                        label: const Text(
                          'Đặt lịch với BS',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPricingTab({
    required List<Map<String, dynamic>> departments,
    required List<Map<String, dynamic>> pricingPreview,
  }) {
    final filtered = pricingPreview.where((s) {
      if (_selectedDepartmentFilterId == null) return true;
      final dId = (s['chuyen_khoa_id'] as num?)?.toInt();
      return dId == _selectedDepartmentFilterId;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bảng giá Dịch vụ và Viện phí Minh bạch',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tất cả dịch vụ khám chữa bệnh và kỹ thuật cận lâm sàng được niêm yết công khai, hỗ trợ thanh toán trừ chi phí BHYT đúng tuyến.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.slate600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (departments.isNotEmpty) ...[
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ActionChip(
                  label: const Text('Tất cả'),
                  backgroundColor: _selectedDepartmentFilterId == null
                      ? AppColors.medical600
                      : Colors.white,
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _selectedDepartmentFilterId == null
                        ? Colors.white
                        : AppColors.slate700,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedDepartmentFilterId = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...departments.map((d) {
                  final dId = (d['id'] as num?)?.toInt();
                  final isSelected = _selectedDepartmentFilterId == dId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text('${d['ten_khoa']}'),
                      backgroundColor:
                          isSelected ? AppColors.medical600 : Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.slate700,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedDepartmentFilterId = dId;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: filtered.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('Không có dịch vụ nào trong chuyên khoa này.'),
                  ),
                )
              : Column(
                  children: [
                    ...filtered.map((s) {
                      final donGia = s['don_gia_val'] ?? s['don_gia'] ?? 0;
                      final giaBhyt = s['gia_sau_bhyt_val'] ?? donGia;
                      return ListTile(
                        dense: true,
                        title: Text(
                          '${s['ten_dich_vu'] ?? ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.slate800,
                          ),
                        ),
                        subtitle: Text(
                          '${s['ten_khoa_hien_thi'] ?? s['ten_khoa'] ?? 'Đa khoa'} • ${s['loai_dich_vu'] ?? 'Khám bệnh'}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.slate500,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              patientMoney(donGia),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.slate800,
                              ),
                            ),
                            Text(
                              'BHYT: ${patientMoney(giaBhyt)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.medical600,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PricingScreen(
                                initialDepartmentId:
                                    (s['chuyen_khoa_id'] as num?)?.toInt(),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                    const Divider(height: 1),
                    InkWell(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PricingScreen(),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 13),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Tra cứu toàn bộ danh mục Bảng giá và BHYT',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.medical700,
                              ),
                            ),
                            SizedBox(width: 5),
                            Icon(Icons.arrow_forward_rounded,
                                size: 16, color: AppColors.medical700),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildArticlesTab({
    required List<Map<String, dynamic>> articles,
    required List<Map<String, dynamic>> handbooks,
    required List<dynamic> categories,
  }) {
    final combined = <Map<String, dynamic>>[
      ...articles,
      ...handbooks.where(
        (h) => !articles.any((a) => a['id'] == h['id']),
      ),
    ];

    final filtered = combined.where((art) {
      if (_selectedCategoryFilter == null) return true;
      final cat = (art['category_name'] ?? art['chuyen_muc'] ?? '').toString();
      return cat == _selectedCategoryFilter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tin tức Y khoa và Cẩm nang Sức khỏe',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Kiến thức phòng ngừa bệnh tật, tư vấn lối sống lành mạnh và hướng dẫn sơ cứu từ các bác sĩ chuyên khoa.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.slate600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (categories.isNotEmpty) ...[
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ActionChip(
                  label: const Text('Tất cả'),
                  backgroundColor: _selectedCategoryFilter == null
                      ? AppColors.medical600
                      : Colors.white,
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _selectedCategoryFilter == null
                        ? Colors.white
                        : AppColors.slate700,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedCategoryFilter = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...categories.map((c) {
                  final catName = c is Map
                      ? (c['name'] ?? '').toString()
                      : c.toString();
                  final isSelected = _selectedCategoryFilter == catName;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(catName),
                      backgroundColor:
                          isSelected ? AppColors.medical600 : Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.slate700,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedCategoryFilter = catName;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (filtered.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Chưa có bài viết trong danh mục này.'),
            ),
          )
        else
          ...filtered.map((art) {
            final imgUrl = PatientApiService.mediaUrl(art['image']);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArticleDetailScreen(
                        slug: (art['slug'] ?? '').toString(),
                        initialArticle: art,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 72,
                          height: 72,
                          color: AppColors.medical50,
                          child: imgUrl != null
                              ? Image.network(
                                  imgUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.article_outlined,
                                    color: AppColors.medical600,
                                  ),
                                )
                              : const Icon(
                                  Icons.article_outlined,
                                  color: AppColors.medical600,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.medical50,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                '${art['category_name'] ?? 'Cẩm Nang Y Tế'}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.medical700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${art['title'] ?? ''}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.slate800,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${art['published_at'] ?? ''} • ${art['read_time'] ?? 5} phút đọc',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.slate400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        Center(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArticlesScreen()),
              );
            },
            icon: const Icon(Icons.menu_book, size: 18),
            label: const Text('Xem toàn bộ kho Tin tức và Cẩm nang'),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessTab() {
    final steps = [
      {
        'step': '1',
        'title': 'Đăng ký và Đặt lịch hẹn trực tuyến',
        'desc':
            'Chủ động chọn chuyên khoa, bác sĩ mong muốn và khung giờ khám phù hợp ngay trên ứng dụng di động để không phải xếp hàng chờ đợi.',
        'icon': Icons.calendar_month,
        'color': AppColors.medical600,
      },
      {
        'step': '2',
        'title': 'Tiếp đón và Khám lâm sàng',
        'desc':
            'Đến phòng khám trước giờ hẹn 10 phút, check-in quét mã QR tại quầy lễ tân hoặc kiosk tự động. Bác sĩ chuyên khoa trực tiếp thăm khám kỹ lưỡng.',
        'icon': Icons.how_to_reg,
        'color': Colors.blueAccent,
      },
      {
        'step': '3',
        'title': 'Chỉ định và Thực hiện Cận lâm sàng',
        'desc':
            'Thực hiện các dịch vụ siêu âm, chụp X-quang, đo điện tim hoặc xét nghiệm máu bằng hệ thống trang thiết bị hiện đại nếu bác sĩ có chỉ định.',
        'icon': Icons.science,
        'color': Colors.purple,
      },
      {
        'step': '4',
        'title': 'Nhận kết quả, Cấp đơn thuốc và Lĩnh thuốc',
        'desc':
            'Toàn bộ kết quả xét nghiệm được đồng bộ tức thì lên ứng dụng. Bác sĩ tư vấn phác đồ và cấp đơn thuốc điện tử (nhận tại quầy dược bệnh viện hoặc tự mua ngoài).',
        'icon': Icons.medication,
        'color': AppColors.medical600,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quy trình Khám chữa bệnh tại H2T Healthcare',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Quy trình 4 bước tinh gọn, khép kín, ứng dụng chuyển đổi số toàn diện giúp người bệnh tiết kiệm tối đa thời gian và an tâm khám chữa bệnh.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.slate600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...steps.map((st) {
          final color = st['color'] as Color;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Text(
                    st['step'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        st['title'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        st['desc'] as String,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.slate600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.tips_and_updates_outlined,
                      size: 20, color: AppColors.medical700),
                  SizedBox(width: 8),
                  Text(
                    'Lưu ý quan trọng khi đi khám',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.medical900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '• Mang theo thẻ Căn cước công dân và thẻ BHYT bản cứng hoặc mở sẵn trên ứng dụng VNeID / H2T Healthcare.\n'
                '• Mang theo hồ sơ bệnh án, sổ khám bệnh và các toa thuốc đang dùng nếu có.\n'
                '• Nhịn ăn sáng từ 6 đến 8 tiếng nếu dự kiến có chỉ định xét nghiệm máu hoặc siêu âm ổ bụng.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.medical900,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.medical600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _navigateToAppointment(),
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: const Text(
                    'Đặt lịch khám theo quy trình ngay',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thông tin liên hệ và Hỗ trợ',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 18, color: AppColors.medical600),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Địa chỉ: 123 Đường Y Học, Phường 10, Quận 10, TP. Hồ Chí Minh',
                      style: TextStyle(fontSize: 12.5, color: AppColors.slate700),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.phone_in_talk_outlined,
                      size: 18, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text(
                    'Hotline tư vấn và cấp cứu: 1900 6868',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time_outlined,
                      size: 18, color: AppColors.slate600),
                  SizedBox(width: 8),
                  Text(
                    'Giờ làm việc: 07:00 - 20:30 (Thứ 2 đến Chủ nhật)',
                    style: TextStyle(fontSize: 12.5, color: AppColors.slate700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final upcomingMap = _dashboardData?['upcoming_appointment'] is Map
        ? Map<String, dynamic>.from(
            _dashboardData!['upcoming_appointment'] as Map,
          )
        : null;
    final unreadNotifs = (_dashboardData?['unread_notifications'] as int?) ?? 0;
    final error = _publicError ?? _error ??
        (user == null ? context.watch<AuthViewModel>().errorMessage : null);

    final banners = List<Map<String, dynamic>>.from(
      (_publicHomeData?['banners'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final departments = List<Map<String, dynamic>>.from(
      (_publicHomeData?['departments'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final doctors = List<Map<String, dynamic>>.from(
      (_publicHomeData?['doctors'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final pricingPreview = List<Map<String, dynamic>>.from(
      (_publicHomeData?['pricing_preview'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final articles = List<Map<String, dynamic>>.from(
      (_publicHomeData?['articles'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final handbooks = List<Map<String, dynamic>>.from(
      (_publicHomeData?['handbooks'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final feedbacks = List<Map<String, dynamic>>.from(
      (_publicHomeData?['feedbacks'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final categories = (_publicHomeData?['categories'] as List? ?? []);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SafeArea(
        child: Column(
          children: [
            HeaderWidget(
              unreadCount: unreadNotifs,
              onRefresh: () {
                _fetchPublicHome();
                if (user != null) _fetchDashboard(user.token);
              },
            ),
            _buildHorizontalMenu(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _fetchPublicHome();
                  if (user != null) {
                    await _fetchDashboard(user.token);
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (error != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(
                                error,
                                style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                              )),
                              TextButton(onPressed: _fetchPublicHome, child: const Text('Thử lại')),
                            ],
                          ),
                        ),
                      AppTabTransition(
                        switchKey: ValueKey<int>(_selectedTabIndex),
                        child: _selectedTabIndex == 0
                            ? _buildOverviewTab(
                                banners: banners,
                                departments: departments,
                                doctors: doctors,
                                articles: articles,
                                feedbacks: feedbacks,
                                upcomingMap: upcomingMap,
                              )
                            : _selectedTabIndex == 1
                                ? _buildDepartmentsTab(departments)
                                : _selectedTabIndex == 2
                                    ? _buildDoctorsTab(doctors)
                                    : _selectedTabIndex == 3
                                        ? _buildPricingTab(
                                            departments: departments,
                                            pricingPreview: pricingPreview,
                                          )
                                        : _selectedTabIndex == 4
                                            ? _buildArticlesTab(
                                                articles: articles,
                                                handbooks: handbooks,
                                                categories: categories,
                                              )
                                            : _buildProcessTab(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
