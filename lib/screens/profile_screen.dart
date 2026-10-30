import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import 'auth_screen.dart';
import 'billing_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User? user;
  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PatientApiService _apiService = PatientApiService();
  String? _lastToken;
  Map<String, dynamic> _profileData = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = widget.user?.token ?? context.watch<AuthViewModel>().currentUser?.token;
    if (token != _lastToken) {
      _lastToken = token;
      if (token != null && token.isNotEmpty) {
        _loadProfile(token);
      } else {
        setState(() => _profileData = {});
      }
    }
  }

  Future<void> _loadProfile(String token) async {
    try {
      final data = await _apiService.getProfile(token);
      if (!mounted) return;
      setState(() => _profileData = data);
    } catch (_) {}
  }

  void _openAuthScreen(
    BuildContext context, {
    AuthMode initialMode = AuthMode.login,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthScreen(initialMode: initialMode),
      ),
    );
  }

  Future<void> _showEditMedicalProfileSheet(BuildContext context, User currentUser) async {
    await _loadProfile(currentUser.token);
    if (!context.mounted) return;

    final hoTenCtrl = TextEditingController(
      text: (_profileData['ho_ten'] ?? currentUser.name).toString(),
    );
    final ngaySinhCtrl = TextEditingController(
      text: (_profileData['ngay_sinh'] ?? '1995-05-15').toString(),
    );
    String gioiTinh = (_profileData['gioi_tinh'] ?? 'Nam').toString();
    if (!['Nam', 'Nữ', 'Khác'].contains(gioiTinh)) {
      gioiTinh = 'Nam';
    }
    final cccdCtrl = TextEditingController(
      text: (_profileData['so_cccd'] ?? _profileData['cccd'] ?? '').toString(),
    );
    final diaChiCtrl = TextEditingController(
      text: (_profileData['dia_chi'] ?? '').toString(),
    );
    final bhytCtrl = TextEditingController(
      text: (_profileData['so_the_bhyt'] ?? _profileData['bhyt'] ?? '').toString(),
    );
    final hanBhytCtrl = TextEditingController(
      text: (_profileData['han_the_bhyt'] ?? '2026-12-31').toString(),
    );
    final nhomMauCtrl = TextEditingController(
      text: (_profileData['nhom_mau'] ?? 'O+').toString(),
    );
    final diUngCtrl = TextEditingController(
      text: (_profileData['di_ung'] ?? '').toString(),
    );
    final benhNenCtrl = TextEditingController(
      text: (_profileData['benh_nen'] ?? _profileData['tien_su_benh'] ?? '').toString(),
    );
    final khanCapCtrl = TextEditingController(
      text: (_profileData['lien_he_khan_cap'] ?? _profileData['nguoi_than_sdt'] ?? '').toString(),
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cập nhật Hồ sơ Y tế & BHYT',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate800,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(hoTenCtrl, 'Họ và tên'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            ngaySinhCtrl,
                            'Ngày sinh (YYYY-MM-DD)',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DropdownButtonFormField<String>(
                              value: gioiTinh,
                              decoration: const InputDecoration(
                                labelText: 'Giới tính',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                                DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                                DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => gioiTinh = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    _buildTextField(cccdCtrl, 'Số CCCD / Định danh'),
                    _buildTextField(diaChiCtrl, 'Địa chỉ thường trú'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(bhytCtrl, 'Mã thẻ BHYT (15 ký tự)'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            hanBhytCtrl,
                            'Hạn BHYT (YYYY-MM-DD)',
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(nhomMauCtrl, 'Nhóm máu (A, B, AB, O)'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(khanCapCtrl, 'SĐT Liên hệ khẩn cấp'),
                        ),
                      ],
                    ),
                    _buildTextField(diUngCtrl, 'Tiền sử dị ứng (Thuốc, thức ăn...)'),
                    _buildTextField(benhNenCtrl, 'Bệnh lý nền (Tim mạch, tiểu đường...)'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                setModalState(() => isSaving = true);
                                try {
                                  await _apiService.updateProfile(
                                    token: currentUser.token,
                                    payload: {
                                      'ho_ten': hoTenCtrl.text.trim(),
                                      'ngay_sinh': ngaySinhCtrl.text.trim(),
                                      'gioi_tinh': gioiTinh,
                                      'so_cccd': cccdCtrl.text.trim(),
                                      'dia_chi': diaChiCtrl.text.trim(),
                                      'so_the_bhyt': bhytCtrl.text.trim(),
                                      'han_the_bhyt': hanBhytCtrl.text.trim(),
                                      'nhom_mau': nhomMauCtrl.text.trim(),
                                      'di_ung': diUngCtrl.text.trim(),
                                      'benh_nen': benhNenCtrl.text.trim(),
                                      'lien_he_khan_cap': khanCapCtrl.text.trim(),
                                    },
                                  );
                                  await _loadProfile(currentUser.token);
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppColors.emerald500,
                                      content: Text(
                                        'Đã lưu hồ sơ sức khỏe & BHYT vào SQL Server!',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  setModalState(() => isSaving = false);
                                  if (!ctx.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppColors.rose500,
                                      content: Text(
                                        e.toString().replaceFirst('Exception: ', ''),
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.medical600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isSaving ? 'Đang lưu...' : 'Lưu thông tin hồ sơ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showFeedbackSheet(BuildContext context, User currentUser) async {
    List<Map<String, dynamic>> history = [];
    try {
      history = await _apiService.getFeedbacks(currentUser.token);
    } catch (_) {}

    if (!context.mounted) return;
    final contentCtrl = TextEditingController();
    int selectedStars = 5;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Đánh giá & Góp ý Dịch vụ Y tế',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate800,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mức độ hài lòng của bạn:',
                      style: TextStyle(fontSize: 13, color: AppColors.slate600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (idx) {
                        final starValue = idx + 1;
                        return IconButton(
                          onPressed: () =>
                              setModalState(() => selectedStars = starValue),
                          icon: Icon(
                            starValue <= selectedStars
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: AppColors.amber500,
                            size: 36,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: contentCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Nội dung nhận xét / góp ý',
                        hintText: 'Chia sẻ trải nghiệm khám chữa bệnh tại phòng khám...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (contentCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Vui lòng nhập nội dung đánh giá.'),
                                    ),
                                  );
                                  return;
                                }
                                setModalState(() => isSubmitting = true);
                                try {
                                  await _apiService.submitFeedback(
                                    token: currentUser.token,
                                    soSao: selectedStars,
                                    noiDung: contentCtrl.text.trim(),
                                  );
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppColors.emerald500,
                                      content: Text(
                                        'Cảm ơn bạn đã gửi đánh giá dịch vụ!',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  setModalState(() => isSubmitting = false);
                                  if (!ctx.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppColors.rose500,
                                      content: Text(
                                        e.toString().replaceFirst('Exception: ', ''),
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.medical600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isSubmitting ? 'Đang lưu...' : 'Gửi đánh giá',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (history.isNotEmpty) ...[
                      const Divider(height: 24),
                      const Text(
                        'Đánh giá trước đây của bạn:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...history.take(3).map((fb) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.slate50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '⭐ ${fb['so_sao'] ?? fb['diem_danh_gia'] ?? 5}/5 • ${fb['ngay_gui'] ?? fb['thoi_gian_gui'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.amber500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (fb['noi_dung'] ?? '').toString(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.slate700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = widget.user ?? authViewModel.currentUser;
    final isAuthenticated = currentUser != null;
    final displayName = isAuthenticated
        ? (_profileData['ho_ten']?.toString().isNotEmpty == true
            ? _profileData['ho_ten'].toString()
            : currentUser.name)
        : 'Khách tham quan';
    final secondaryInfo = isAuthenticated
        ? 'SĐT: ${currentUser.phone} | Mã BN: ${currentUser.patientCode}'
        : 'Đăng nhập để đồng bộ lịch hẹn và hồ sơ bệnh án';

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(
                top: 40,
                bottom: 30,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.medical500,
                            width: 3,
                          ),
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.medical600,
                          shape: BoxShape.circle,
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.camera,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    secondaryInfo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: isAuthenticated
                  ? _buildAuthenticatedActions(context, authViewModel, currentUser)
                  : _buildGuestActions(context),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestActions(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.medical50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.userCheck,
                color: AppColors.medical600,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bạn chưa đăng nhập',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhấn vào nút bên dưới để đăng nhập hoặc tạo tài khoản bệnh nhân mới khi cần sử dụng các tính năng cá nhân.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.slate500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _openAuthScreen(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.medical600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const FaIcon(FontAwesomeIcons.rightToBracket, size: 16),
              label: const Text(
                'Đăng nhập / Đăng ký',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticatedActions(
    BuildContext context,
    AuthViewModel authViewModel,
    User currentUser,
  ) {
    final bhyt = (_profileData['so_the_bhyt'] ?? _profileData['bhyt'] ?? '').toString();
    final nhomMau = (_profileData['nhom_mau'] ?? 'Chưa rõ').toString();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.medical50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.medical100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text(
                    'Nhóm máu',
                    style: TextStyle(fontSize: 11, color: AppColors.slate500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nhomMau,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.medical600,
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 28, color: AppColors.medical100),
              Column(
                children: [
                  const Text(
                    'Thẻ BHYT',
                    style: TextStyle(fontSize: 11, color: AppColors.slate500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bhyt.isNotEmpty ? bhyt : 'Chưa cập nhật',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildMenuGroup([
          _buildMenuItem(
            FontAwesomeIcons.userPen,
            'Cập nhật hồ sơ y tế & BHYT',
            onTap: () => _showEditMedicalProfileSheet(context, currentUser),
          ),
          _buildMenuItem(
            FontAwesomeIcons.star,
            'Đánh giá & Góp ý dịch vụ (5 sao)',
            onTap: () => _showFeedbackSheet(context, currentUser),
          ),
          _buildMenuItem(
            FontAwesomeIcons.creditCard,
            'Viện phí & Khấu trừ BHYT',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BillingScreen()),
              );
            },
          ),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              authViewModel.logout();
            },
            icon: const FaIcon(
              FontAwesomeIcons.rightFromBracket,
              color: AppColors.rose500,
              size: 16,
            ),
            label: const Text(
              'Đăng xuất tài khoản',
              style: TextStyle(
                color: AppColors.rose500,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.rose500),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuGroup(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(children: items),
    );
  }

  Widget _buildMenuItem(
    FaIconData icon,
    String title, {
    String? trailingText,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: FaIcon(icon, size: 16, color: AppColors.slate600),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.slate800,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: const TextStyle(fontSize: 12, color: AppColors.slate400),
            ),
          if (trailingText != null) const SizedBox(width: 8),
          const FaIcon(
            FontAwesomeIcons.chevronRight,
            size: 12,
            color: AppColors.slate400,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
