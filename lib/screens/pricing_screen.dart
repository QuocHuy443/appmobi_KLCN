import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import '../core/patient_format.dart';
import '../services/patient_api_service.dart';
import '../widgets/request_error.dart';
import 'appointment_screen.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key, this.initialDepartmentId});

  final int? initialDepartmentId;

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final PatientApiService _api = PatientApiService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  late int? _selectedDeptId = widget.initialDepartmentId;
  List<Map<String, dynamic>> _departmentsPricing = [];
  int _totalServices = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getPublicPricing();
      if (!mounted) return;
      final depts = List<Map<String, dynamic>>.from(
        (data['departments_pricing'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      setState(() {
        _departmentsPricing = depts;
        _totalServices = (data['total_services'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredDepartments {
    final q = _searchController.text.trim().toLowerCase();
    final result = <Map<String, dynamic>>[];

    for (final dept in _departmentsPricing) {
      final deptId = (dept['id'] as num?)?.toInt() ?? 0;
      if (_selectedDeptId != null && deptId != _selectedDeptId) continue;

      final rawServices = List<Map<String, dynamic>>.from(
        (dept['services'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      final matched = q.isEmpty
          ? rawServices
          : rawServices.where((s) {
              final text = [
                s['ten_dich_vu'],
                s['ma_dich_vu'],
                s['loai_dich_vu'],
                s['mo_ta'],
                dept['ten_khoa'],
              ].map((e) => (e ?? '').toString().toLowerCase()).join(' ');
              return text.contains(q);
            }).toList();

      if (matched.isNotEmpty) {
        final copy = Map<String, dynamic>.from(dept);
        copy['filtered_services'] = matched;
        result.add(copy);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final filteredDepts = _filteredDepartments;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Bảng giá Dịch vụ và Viện phí',
          style: TextStyle(
            color: AppColors.slate800,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới bảng giá',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh, color: AppColors.medical600),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeroBanner(),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tìm tên dịch vụ, xét nghiệm, siêu âm, chuyên khoa...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_departmentsPricing.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('Tất cả ($_totalServices)'),
                      selected: _selectedDeptId == null,
                      onSelected: (_) => setState(() => _selectedDeptId = null),
                    ),
                    const SizedBox(width: 8),
                    ..._departmentsPricing.map((dept) {
                      final id = (dept['id'] as num?)?.toInt() ?? 0;
                      final count = dept['services_count'] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${dept['ten_khoa']} ($count)'),
                          selected: _selectedDeptId == id,
                          onSelected: (_) => setState(
                            () => _selectedDeptId =
                                _selectedDeptId == id ? null : id,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              RequestError(message: _error!, onRetry: _load)
            else if (filteredDepts.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: const Text(
                  'Không tìm thấy dịch vụ phù hợp với bộ lọc hiện tại.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.slate600),
                ),
              )
            else
              ...filteredDepts.map(_buildDepartmentSection),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  FontAwesomeIcons.fileInvoiceDollar,
                  size: 12,
                  color: Colors.amberAccent,
                ),
                SizedBox(width: 6),
                Text(
                  'MINH BẠCH • NIÊM YẾT CÔNG KHAI • CHUẨN BỘ Y TẾ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Bảng Giá Dịch Vụ Khám Chữa Bệnh và Viện Phí',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Công khai biểu giá dịch vụ kỹ thuật y tế, viện phí khám bệnh và mức hỗ trợ BHYT của từng dịch vụ.',
            style: TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildHighlightPill(Icons.verified_user_outlined, 'BHYT Toàn Quốc'),
              const SizedBox(width: 8),
              _buildHighlightPill(Icons.receipt_long_outlined, 'Không Phí Ẩn'),
              const SizedBox(width: 8),
              _buildHighlightPill(Icons.badge_outlined, 'CCCD và VssID'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightPill(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppColors.medical300),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentSection(Map<String, dynamic> dept) {
    final services = List<Map<String, dynamic>>.from(
      dept['filtered_services'] as List? ?? [],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.medical50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.medical600,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${dept['ten_khoa'] ?? 'Chuyên khoa'}',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate800,
                        ),
                      ),
                      Text(
                        '${services.length} dịch vụ niêm yết',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppointmentScreen(initialTab: 0),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_month, size: 16),
                  label: const Text(
                    'Đặt khám',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.slate100),
            itemBuilder: (_, idx) {
              final s = services[idx];
              final donGia = s['don_gia_val'] ?? s['don_gia'] ?? 0;
              final giaSauBhyt = s['gia_sau_bhyt_val'] ?? donGia;
              final tienBhyt = s['tien_bhyt_val'] ?? 0;
              final loai = (s['loai_dich_vu'] ?? 'Khám bệnh').toString();
              final moTa = (s['mo_ta'] ?? '').toString().trim();

              return Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.slate100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      loai,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.slate600,
                                      ),
                                    ),
                                  ),
                                  if (s['ma_dich_vu'] != null) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '#${s['ma_dich_vu']}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.slate400,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${s['ten_dich_vu'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate800,
                                ),
                              ),
                              if (moTa.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  moTa,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.slate500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Giá gốc (Chưa BHYT)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.slate500,
                                ),
                              ),
                              Text(
                                patientMoney(donGia),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate800,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Có BHYT (Giảm ${patientMoney(tienBhyt)})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.medical700,
                                ),
                              ),
                              Text(
                                patientMoney(giaSauBhyt),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.medical600,
                                ),
                              ),
                            ],
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
    );
  }
}
