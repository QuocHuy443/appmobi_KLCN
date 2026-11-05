import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import '../widgets/request_error.dart';
import '../widgets/vip_card_widget.dart';
import 'articles_screen.dart';
import 'auth_screen.dart';
import 'billing_screen.dart';
import 'feedback_screen.dart';
import 'medical_records_screen.dart';
import 'notifications_screen.dart';
import 'personal_profile_screen.dart';
import 'pricing_screen.dart';
import 'test_results_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.user, this.refreshVersion = 0});
  final User? user;
  final int refreshVersion;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = PatientApiService();
  String? _token;
  String? _error;
  bool _loading = false;
  Map<String, dynamic> _profile = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context.watch<AuthViewModel>().currentUser?.token;
    if (token != _token) {
      _token = token;
      _profile = {};
      _error = null;
      if (token != null) _load(token);
    }
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion && _token != null) {
      _load(_token!);
    }
  }

  Future<void> _load(String token) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _api.getProfile(token);
      if (!mounted ||
          context.read<AuthViewModel>().currentUser?.token != token) {
        return;
      }
      setState(() {
        _profile = profile;
        _loading = false;
      });
      context.read<AuthViewModel>().updatePatientProfile(token, profile);
    } catch (e) {
      if (mounted && _token == token) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted && _token != null) _load(_token!);
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: iconColor ?? AppColors.slate500),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.slate500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.slate800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsSection(Map<String, dynamic>? vitals) {
    final v = vitals ?? {};
    final hasAnyVital = v.values.any((val) =>
        val != null &&
        val.toString().trim().isNotEmpty &&
        val.toString() != 'Chưa đo' &&
        val.toString() != '--');

    final vitalItems = [
      {
        'label': 'Mạch',
        'value': v['mach'] != null ? '${v['mach']} bpm' : 'Chưa đo',
        'icon': Icons.favorite,
        'color': Colors.redAccent,
      },
      {
        'label': 'Huyết áp',
        'value': v['huyet_ap'] != null ? '${v['huyet_ap']} mmHg' : 'Chưa đo',
        'icon': Icons.speed,
        'color': Colors.blueAccent,
      },
      {
        'label': 'Nhiệt độ',
        'value': v['nhiet_do'] != null ? '${v['nhiet_do']} °C' : 'Chưa đo',
        'icon': Icons.thermostat,
        'color': Colors.orange,
      },
      {
        'label': 'SpO2',
        'value': v['spo2'] != null ? '${v['spo2']} %' : 'Chưa đo',
        'icon': Icons.air,
        'color': AppColors.medical600,
      },
      {
        'label': 'Chiều cao',
        'value': v['chieu_cao'] != null ? '${v['chieu_cao']} cm' : 'Chưa đo',
        'icon': Icons.height,
        'color': Colors.indigo,
      },
      {
        'label': 'Cân nặng',
        'value': v['can_nang'] != null ? '${v['can_nang']} kg' : 'Chưa đo',
        'icon': Icons.monitor_weight_outlined,
        'color': Colors.purple,
      },
    ];

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.slate200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.monitor_heart,
                  size: 20,
                  color: AppColors.medical600,
                ),
                SizedBox(width: 8),
                Text(
                  'Chỉ số sinh tồn lần khám gần nhất',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Ghi nhận từ bệnh án khám bệnh gần nhất trong CSDL, dùng để tham khảo lịch sử sức khỏe cá nhân.',
              style: TextStyle(fontSize: 11.5, color: AppColors.slate500),
            ),
            const SizedBox(height: 12),
            if (!hasAnyVital)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.slate400),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chưa có chỉ số sinh tồn lưu trữ. Chỉ số sẽ được cập nhật tự động sau khi bạn hoàn thành buổi khám tại phòng khám.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.slate600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: vitalItems.length,
                itemBuilder: (_, idx) {
                  final it = vitalItems[idx];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          it['icon'] as IconData,
                          color: it['color'] as Color,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it['label'] as String,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.slate500,
                                ),
                              ),
                              Text(
                                it['value'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.currentUser;
    final avatar = PatientApiService.avatarUrl(_profile['avatar']);
    final vitalsMap = _profile['vitals'] is Map
        ? Map<String, dynamic>.from(_profile['vitals'] as Map)
        : null;

    final bhytVal = _profile['so_the_bhyt']?.toString() ??
        _profile['bhyt']?.toString() ??
        'Chưa cập nhật';
    final nhomMauVal = _profile['nhom_mau']?.toString() ?? 'Chưa rõ';
    final cccdVal = _profile['so_cccd']?.toString() ??
        _profile['cccd']?.toString() ??
        'Chưa cập nhật';
    final ngaySinhVal = _profile['ngay_sinh']?.toString() ?? 'Chưa cập nhật';
    final gioiTinhVal = _profile['gioi_tinh']?.toString() ?? 'Chưa cập nhật';
    final tienSuVal = _profile['tien_su_benh']?.toString() ??
        _profile['benh_nen']?.toString() ??
        'Không có ghi nhận đặc biệt';
    final emergencyPhone = _profile['nguoi_than_sdt']?.toString() ??
        _profile['lien_he_khan_cap']?.toString() ??
        'Chưa cập nhật';

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Hồ sơ của tôi'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (user != null) await _load(user.token);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (user == null)
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.slate200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 44,
                        color: AppColors.medical600,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Bạn chưa đăng nhập',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (auth.errorMessage != null)
                        Text(
                          auth.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      const Text(
                        'Đăng nhập để xem thẻ định danh bệnh nhân, hồ sơ bệnh án, lịch khám và kết quả xét nghiệm.',
                        style: TextStyle(color: AppColors.slate600),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _open(const AuthScreen()),
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('Đăng nhập / Đăng ký'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              VipCardWidget(
                bhyt: bhytVal != 'Chưa cập nhật' ? bhytVal : null,
                nhomMau: nhomMauVal != 'Chưa rõ' ? nhomMauVal : null,
              ),
              const SizedBox(height: 14),
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.slate200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.medical100,
                            backgroundImage: avatar == null
                                ? null
                                : NetworkImage(avatar),
                            onBackgroundImageError:
                                avatar == null ? null : (_, __) {},
                            child: avatar == null
                                ? const Icon(
                                    Icons.person,
                                    size: 30,
                                    color: AppColors.medical700,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.slate800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Mã BN: ${user.patientCode}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.medical700,
                                  ),
                                ),
                                Text(
                                  'SĐT: ${user.phone}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.slate500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Chỉnh sửa hồ sơ',
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.medical600,
                            ),
                            onPressed: () => _open(const PersonalProfileScreen()),
                          ),
                        ],
                      ),
                      const Divider(height: 22),
                      const Text(
                        'Thông tin định danh và y tế',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        icon: Icons.badge_outlined,
                        label: 'Số CCCD/Định danh:',
                        value: cccdVal,
                      ),
                      _buildInfoRow(
                        icon: Icons.cake_outlined,
                        label: 'Ngày sinh:',
                        value: ngaySinhVal,
                      ),
                      _buildInfoRow(
                        icon: Icons.wc_outlined,
                        label: 'Giới tính:',
                        value: gioiTinhVal,
                      ),
                      _buildInfoRow(
                        icon: Icons.credit_card,
                        label: 'Thẻ BHYT:',
                        value: bhytVal,
                        iconColor: AppColors.medical600,
                      ),
                      _buildInfoRow(
                        icon: Icons.bloodtype_outlined,
                        label: 'Nhóm máu:',
                        value: nhomMauVal,
                        iconColor: Colors.redAccent,
                      ),
                      _buildInfoRow(
                        icon: Icons.medical_information_outlined,
                        label: 'Tiền sử bệnh:',
                        value: tienSuVal,
                      ),
                      _buildInfoRow(
                        icon: Icons.contact_phone_outlined,
                        label: 'Liên hệ khẩn cấp:',
                        value: emergencyPhone,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildVitalsSection(vitalsMap),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
              if (_error != null)
                RequestError(
                  message: _error!,
                  onRetry: () => _load(user.token),
                ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'Nghiệp vụ và Dịch vụ của tôi',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate800,
                  ),
                ),
              ),
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.slate200),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.medical50,
                        child: Icon(Icons.manage_accounts,
                            size: 19, color: AppColors.medical600),
                      ),
                      title: const Text(
                        'Thông tin cá nhân và ảnh đại diện',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Cập nhật CCCD, BHYT, địa chỉ liên hệ',
                          style: TextStyle(fontSize: 11.5)),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _open(const PersonalProfileScreen()),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const CircleAvatar(
                        radius: 17,
                        backgroundColor: Color(0xFFEFF6FF),
                        child: Icon(Icons.receipt_long,
                            size: 19, color: Colors.blueAccent),
                      ),
                      title: const Text(
                        'Hồ sơ bệnh án và đơn thuốc',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Xem lịch sử khám, chẩn đoán và đơn thuốc',
                          style: TextStyle(fontSize: 11.5)),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _open(const MedicalRecordsScreen()),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const CircleAvatar(
                        radius: 17,
                        backgroundColor: Color(0xFFF5F3FF),
                        child: Icon(Icons.science,
                            size: 19, color: Colors.deepPurple),
                      ),
                      title: const Text(
                        'Kết quả xét nghiệm và cận lâm sàng',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Xem chỉ số xét nghiệm, kết luận và hình ảnh',
                          style: TextStyle(fontSize: 11.5)),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _open(const TestResultsScreen()),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const CircleAvatar(
                        radius: 17,
                        backgroundColor: Color(0xFFECFDF5),
                        child: Icon(Icons.payments_outlined,
                            size: 19, color: AppColors.medical600),
                      ),
                      title: const Text(
                        'Hóa đơn và viện phí',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Chi tiết chi phí, BHYT thanh toán và mã QR',
                          style: TextStyle(fontSize: 11.5)),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _open(const BillingScreen()),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const CircleAvatar(
                        radius: 17,
                        backgroundColor: Color(0xFFFFFBEB),
                        child: Icon(Icons.rate_review,
                            size: 19, color: Colors.amber),
                      ),
                      title: const Text(
                        'Góp ý và đánh giá dịch vụ',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Gửi ý kiến đóng góp cho phòng khám',
                          style: TextStyle(fontSize: 11.5)),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _open(const FeedbackScreen()),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const CircleAvatar(
                        radius: 17,
                        backgroundColor: Color(0xFFFFF1F2),
                        child: Icon(Icons.notifications,
                            size: 19, color: Colors.redAccent),
                      ),
                      title: const Text(
                        'Thông báo từ phòng khám',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Nhắc lịch khám, thông báo bảo trì và tin tức',
                          style: TextStyle(fontSize: 11.5)),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _open(const NotificationsScreen()),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                'Tra cứu thông tin phòng khám',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800,
                ),
              ),
            ),
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.slate200),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.medical50,
                      child: Icon(
                        Icons.price_check_rounded,
                        size: 19,
                        color: AppColors.medical600,
                      ),
                    ),
                    title: const Text(
                      'Bảng giá dịch vụ và viện phí',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Niêm yết công khai và mức giảm trừ BHYT',
                        style: TextStyle(fontSize: 11.5)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _open(const PricingScreen()),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const CircleAvatar(
                      radius: 17,
                      backgroundColor: Color(0xFFF0FDFA),
                      child: Icon(
                        Icons.newspaper_rounded,
                        size: 19,
                        color: Colors.teal,
                      ),
                    ),
                    title: const Text(
                      'Tin tức và cẩm nang y khoa',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Bài viết chuyên môn từ các bác sĩ',
                        style: TextStyle(fontSize: 11.5)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _open(const ArticlesScreen()),
                  ),
                ],
              ),
            ),
            if (user != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: auth.isLoading ? null : auth.logout,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text(
                  'Đăng xuất tài khoản',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}
