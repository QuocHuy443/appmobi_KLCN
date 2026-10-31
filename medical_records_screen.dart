import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import 'auth_screen.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  final PatientApiService _apiService = PatientApiService();
  String? _lastToken;
  bool _isLoading = false;
  Map<String, dynamic> _vitals = {
    'huyet_ap': '120/80',
    'nhip_tim': '75',
    'chieu_cao': '170',
    'can_nang': '65',
    'nhiet_do': '36.6',
  };
  List<Map<String, dynamic>> _records = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context.watch<AuthViewModel>().currentUser?.token;
    if (token != _lastToken) {
      _lastToken = token;
      if (token != null && token.isNotEmpty) {
        _loadRecords(token);
      } else {
        setState(() {
          _records = [];
        });
      }
    }
  }

  Future<void> _loadRecords(String token) async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getMedicalRecords(token);
      if (!mounted) return;
      setState(() {
        if (data['vitals'] is Map) {
          _vitals = Map<String, dynamic>.from(data['vitals'] as Map);
        }
        _records = List<Map<String, dynamic>>.from(data['records'] ?? []);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectPurchaseOption(
    int donThuocId,
    String option, {
    bool isLocked = false,
  }) async {
    if (isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.slate700,
          content: Text(
            'Đơn thuốc này đã được cấp phát hoàn tất tại bệnh viện nên không thể thay đổi hình thức.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final token = context.read<AuthViewModel>().currentUser?.token;
    if (token == null) return;
    try {
      final msg = await _apiService.choosePrescriptionPurchaseOption(
        token: token,
        donThuocId: donThuocId,
        option: option,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.emerald500,
          content: Text(msg),
        ),
      );
      await _loadRecords(token);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.rose500,
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text(
            'Hồ Sơ Sức Khỏe (EMR)',
            style: TextStyle(
              color: AppColors.slate800,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (user != null)
              IconButton(
                tooltip: 'Làm mới bệnh án',
                onPressed: () => _loadRecords(user.token),
                icon: const Icon(Icons.refresh, color: AppColors.medical600),
              ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.medical600,
            unselectedLabelColor: AppColors.slate400,
            indicatorColor: AppColors.medical600,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: 'Lịch sử khám & Đơn thuốc'),
              Tab(text: 'Chỉ số sinh tồn'),
            ],
          ),
        ),
        body: user == null
            ? _buildGuestPrompt(context)
            : (_isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: [
                      _buildHistoryTab(),
                      _buildVitalsTab(),
                    ],
                  )),
      ),
    );
  }

  Widget _buildGuestPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaIcon(
              FontAwesomeIcons.fileWaveform,
              size: 48,
              color: AppColors.medical600,
            ),
            const SizedBox(height: 16),
            const Text(
              'Đăng nhập để xem Bệnh án điện tử (EMR), Đơn thuốc và Chỉ số sinh tồn của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.slate600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.medical600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Đăng nhập tài khoản bệnh nhân'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_records.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có hồ sơ khám bệnh nào trong cơ sở dữ liệu.',
          style: TextStyle(color: AppColors.slate500, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final rec = _records[index];
        return _buildRecordCard(rec);
      },
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> rec) {
    // 1. Chẩn đoán & Chuyên khoa (hỗ trợ cả SQL Server và Local Store)
    final diagnosis = (rec['chan_doan'] ??
            rec['chan_doan_icd'] ??
            rec['chan_doan_so_bo'] ??
            'Khám chuyên khoa')
        .toString();
    final department = (rec['ten_chuyen_khoa'] ??
            rec['khoa'] ??
            rec['chuyen_khoa'] ??
            'Đa khoa')
        .toString();
    final doctorName =
        (rec['ten_bac_si'] ?? rec['bac_si'] ?? 'Bác sĩ điều trị').toString();
    final hocVi = (rec['hoc_vi'] ?? '').toString();
    final fullDoctor = hocVi.isNotEmpty ? '$hocVi $doctorName' : doctorName;
    final date =
        (rec['ngay_kham'] ?? rec['thoi_gian_kham'] ?? '').toString();
    final status = (rec['trang_thai'] ?? 'Hoàn thành').toString();
    final symptoms = (rec['trieu_chung'] ?? '').toString();
    final treatment =
        (rec['ket_luan'] ?? rec['huong_dieu_tri'] ?? '').toString();
    final advice = (rec['loi_dan'] ?? '').toString();
    final followUp =
        (rec['lich_tai_kham'] ?? rec['ngay_tai_kham'] ?? '').toString();

    // 2. Cận lâm sàng / Xét nghiệm
    List<Map<String, dynamic>> labs = [];
    if (rec['lab_orders'] is List) {
      labs = List<Map<String, dynamic>>.from(rec['lab_orders']);
    } else if (rec['can_lam_sang'] is List) {
      labs = List<Map<String, dynamic>>.from(rec['can_lam_sang']);
    }

    // 3. Đơn thuốc điện tử & Hình thức nhận thuốc
    final presMap = rec['prescription'] is Map
        ? Map<String, dynamic>.from(rec['prescription'] as Map)
        : null;
    final donThuocId = presMap?['id'] as int? ??
        rec['don_thuoc_id'] as int? ??
        (rec['id'] as int?);
    final maDonThuoc = (presMap?['ma_don_thuoc'] ??
            rec['ma_don_thuoc'] ??
            '')
        .toString();
    final donThuocTrangThai = (presMap?['trang_thai_duyet'] ??
            rec['trang_thai_don_thuoc'] ??
            rec['don_thuoc_trang_thai'] ??
            'Đã kê đơn')
        .toString();
    final hinhThucMua = (presMap?['hinh_thuc_mua'] ??
            rec['hinh_thuc_mua'] ??
            'Chưa chọn')
        .toString();

    List<Map<String, dynamic>> medicines = [];
    if (presMap != null && presMap['items'] is List) {
      medicines = List<Map<String, dynamic>>.from(presMap['items']);
    } else if (rec['don_thuoc'] is List) {
      medicines = List<Map<String, dynamic>>.from(rec['don_thuoc']);
    }

    final isDispensed = donThuocTrangThai == 'Đã cấp thuốc' ||
        donThuocTrangThai == 'Đã nhận thuốc' ||
        donThuocTrangThai == 'Đã cấp phát';
    final isApproved = donThuocTrangThai.contains('Đã duyệt') ||
        donThuocTrangThai == 'Chờ nhận thuốc' ||
        donThuocTrangThai == 'Chưa nhận thuốc';
    final isCanceled = donThuocTrangThai == 'Đã hủy';
    final isLocked = isDispensed || isApproved || isCanceled;

    String effectiveHinhThuc = hinhThucMua;
    if (effectiveHinhThuc == 'Chưa chọn' || effectiveHinhThuc.isEmpty) {
      if (isDispensed || isApproved) {
        effectiveHinhThuc = 'Mua tại bệnh viện';
      }
    }

    final isHospital = effectiveHinhThuc == 'Mua tại bệnh viện' ||
        effectiveHinhThuc == 'hospital';
    final isOutside = effectiveHinhThuc == 'Tự mua ngoài' ||
        effectiveHinhThuc == 'outside' ||
        effectiveHinhThuc == 'Mua ngoài';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Chuyên khoa & Ngày khám
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.medical50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.medical200),
                ),
                child: Text(
                  department,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.medical700,
                  ),
                ),
              ),
              if (date.isNotEmpty)
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Chẩn đoán bệnh (ICD-10)
          Text(
            diagnosis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.slate800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),

          // Bác sĩ điều trị & Trạng thái
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.userDoctor,
                size: 13,
                color: AppColors.medical600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$fullDoctor • Trạng thái: $status',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.slate600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          // Triệu chứng lâm sàng
          if (symptoms.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Triệu chứng: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate700,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      symptoms,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Kết luận / Hướng điều trị
          if (treatment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Kết luận điều trị: $treatment',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.slate700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],

          // Lời dặn bác sĩ
          if (advice.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Lời dặn bác sĩ: $advice',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.slate600,
                ),
              ),
            ),
          ],

          // Hẹn tái khám
          if (followUp.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.amber500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.amber500.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_repeat,
                    size: 15,
                    color: AppColors.amber500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Lịch hẹn tái khám: $followUp',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.amber500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Cận lâm sàng thực hiện
          if (labs.isNotEmpty) ...[
            const Divider(height: 24, color: AppColors.slate200),
            Row(
              children: [
                const Icon(
                  Icons.biotech,
                  size: 16,
                  color: AppColors.medical600,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Cận lâm sàng & Xét nghiệm:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...labs.map((l) {
              final testName =
                  (l['ten_dich_vu'] ?? l['ten'] ?? 'Xét nghiệm').toString();
              final testResult = (l['ket_qua'] ?? 'Đã hoàn thành').toString();
              final testStatus = (l['trang_thai'] ?? 'Đã có kết quả').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.medical600,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            testName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kết quả: $testResult ($testStatus)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.slate600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // KHỐI ĐƠN THUỐC ĐIỆN TỬ VÀ NÚT MUA THUỐC
          if (medicines.isNotEmpty || donThuocId != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4), // soft emerald tint
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.medical300.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề Đơn thuốc & Trạng thái duyệt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.medical100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.medication,
                              size: 18,
                              color: AppColors.medical700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Đơn thuốc điện tử',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate800,
                                ),
                              ),
                              if (maDonThuoc.isNotEmpty)
                                Text(
                                  'Mã đơn: $maDonThuoc',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.slate500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (donThuocTrangThai.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.emerald500.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            donThuocTrangThai,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.medical700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.medical200),
                  const SizedBox(height: 10),

                  // Danh sách từng loại thuốc trong đơn
                  if (medicines.isNotEmpty) ...[
                    ...medicines.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final m = entry.value;
                      final name = (m['ten_thuoc'] ??
                              m['ten'] ??
                              'Thuốc điều trị')
                          .toString();
                      final qty = (m['so_luong'] ?? '').toString();
                      final unit =
                          (m['don_vi'] ?? m['don_vi_tinh'] ?? '').toString();
                      final qtyDisplay = unit.isNotEmpty && !qty.endsWith(unit)
                          ? '$qty $unit'
                          : qty;
                      final dosage =
                          (m['lieu_dung'] ?? m['cach_dung'] ?? '').toString();
                      final price = m['gia'] ?? m['don_gia'];
                      final priceStr = price != null
                          ? '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match match) => '${match[1]}.')} đ'
                          : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(top: 1),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.medical50,
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(color: AppColors.medical300),
                              ),
                              child: Text(
                                '$idx',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.medical700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.slate800,
                                          ),
                                        ),
                                      ),
                                      if (qtyDisplay.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.medical50,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: AppColors.medical200,
                                            ),
                                          ),
                                          child: Text(
                                            'SL: $qtyDisplay',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.medical700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (dosage.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      'Hướng dẫn: $dosage',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.slate600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                  if (priceStr.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      'Đơn giá: $priceStr',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.slate500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 6),

                  // Thanh trạng thái lựa chọn hình thức nhận thuốc
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isHospital
                          ? AppColors.medical50
                          : (isOutside ? AppColors.slate100 : Colors.amber.shade50),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isHospital
                            ? AppColors.medical300
                            : (isOutside
                                ? AppColors.slate300
                                : Colors.amber.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isHospital
                              ? Icons.check_circle
                              : (isOutside
                                  ? Icons.storefront
                                  : Icons.info_outline),
                          size: 16,
                          color: isHospital
                              ? AppColors.medical700
                              : (isOutside
                                  ? AppColors.slate700
                                  : Colors.amber.shade800),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isDispensed
                                ? 'Hình thức nhận: Mua tại bệnh viện (Đơn đã hoàn tất cấp phát tại Quầy dược bệnh viện)'
                                : (isApproved
                                    ? 'Hình thức nhận: Mua tại bệnh viện (Đơn đã được duyệt, vui lòng thanh toán và nhận thuốc tại quầy)'
                                    : (isHospital
                                        ? 'Hình thức nhận: Mua tại bệnh viện (Đơn chuyển sang quầy thu ngân & kho dược)'
                                        : (isOutside
                                            ? 'Hình thức nhận: Tự mua ngoài (Bệnh nhân tự mua tại nhà thuốc bên ngoài)'
                                            : 'Vui lòng chọn hình thức nhận thuốc:'))),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isHospital
                                  ? AppColors.medical700
                                  : (isOutside
                                      ? AppColors.slate800
                                      : Colors.amber.shade900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 2 Nút hành động: "Mua tại bệnh viện" / "Tự mua ngoài"
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _selectPurchaseOption(
                            donThuocId ?? 0,
                            'Mua tại bệnh viện',
                            isLocked: isLocked,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isHospital
                                ? AppColors.medical600
                                : Colors.white,
                            foregroundColor: isHospital
                                ? Colors.white
                                : AppColors.medical700,
                            elevation: isHospital ? 2 : 0,
                            side: BorderSide(
                              color: isHospital
                                  ? AppColors.medical600
                                  : AppColors.medical400,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 11,
                              horizontal: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Icon(
                            isHospital
                                ? Icons.check_circle_rounded
                                : Icons.local_hospital_outlined,
                            size: 16,
                            color: isHospital
                                ? Colors.white
                                : AppColors.medical600,
                          ),
                          label: const Text(
                            'Mua tại bệnh viện',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _selectPurchaseOption(
                            donThuocId ?? 0,
                            'Tự mua ngoài',
                            isLocked: isLocked,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isOutside
                                ? AppColors.slate800
                                : Colors.white,
                            foregroundColor: isOutside
                                ? Colors.white
                                : AppColors.slate700,
                            elevation: isOutside ? 2 : 0,
                            side: BorderSide(
                              color: isOutside
                                  ? AppColors.slate800
                                  : AppColors.slate300,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 11,
                              horizontal: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Icon(
                            isOutside
                                ? Icons.check_circle_rounded
                                : Icons.storefront_outlined,
                            size: 16,
                            color: isOutside
                                ? Colors.white
                                : AppColors.slate600,
                          ),
                          label: const Text(
                            'Tự mua ngoài',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVitalsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildVitalCard(
          FontAwesomeIcons.heartPulse,
          'Nhịp tim',
          (_vitals['nhip_tim'] ?? '75').toString(),
          'bpm',
          'Bình thường',
          AppColors.rose500,
        ),
        const SizedBox(height: 12),
        _buildVitalCard(
          FontAwesomeIcons.droplet,
          'Huyết áp',
          (_vitals['huyet_ap'] ?? '120/80').toString(),
          'mmHg',
          'Tốt',
          AppColors.medical600,
        ),
        const SizedBox(height: 12),
        _buildVitalCard(
          FontAwesomeIcons.weightScale,
          'Cân nặng & Chiều cao',
          '${_vitals['can_nang'] ?? '65'} kg / ${_vitals['chieu_cao'] ?? '170'} cm',
          '',
          'Ổn định',
          AppColors.emerald500,
        ),
        const SizedBox(height: 12),
        _buildVitalCard(
          FontAwesomeIcons.temperatureHalf,
          'Nhiệt độ cơ thể',
          (_vitals['nhiet_do'] ?? '36.6').toString(),
          '°C',
          'Bình thường',
          AppColors.amber500,
        ),
      ],
    );
  }

  Widget _buildVitalCard(
    FaIconData icon,
    String title,
    String value,
    String unit,
    String status,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: FaIcon(icon, color: color, size: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.slate600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
