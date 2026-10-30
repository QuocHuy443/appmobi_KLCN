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

  Future<void> _selectPurchaseOption(int donThuocId, String option) async {
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
    final diagnosis = (rec['chan_doan_icd'] ?? rec['chan_doan_so_bo'] ?? 'Khám chuyên khoa').toString();
    final department = (rec['khoa'] ?? 'Đa khoa').toString();
    final doctor = (rec['bac_si'] ?? 'Bác sĩ').toString();
    final date = (rec['thoi_gian_kham'] ?? '').toString();
    final status = (rec['trang_thai'] ?? 'Hoàn thành').toString();
    final symptoms = (rec['trieu_chung'] ?? '').toString();
    final treatment = (rec['huong_dieu_tri'] ?? '').toString();
    final advice = (rec['loi_dan'] ?? '').toString();
    final followUp = (rec['lich_tai_kham'] ?? '').toString();
    final donThuocId = rec['don_thuoc_id'] as int?;
    final donThuocTrangThai = (rec['don_thuoc_trang_thai'] ?? '').toString();
    final medicines = List<Map<String, dynamic>>.from(rec['don_thuoc'] ?? []);
    final labs = List<Map<String, dynamic>>.from(rec['can_lam_sang'] ?? []);

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.medical50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  department,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.medical600,
                  ),
                ),
              ),
              Text(
                date,
                style: const TextStyle(fontSize: 12, color: AppColors.slate400),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            diagnosis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.userDoctor,
                size: 12,
                color: AppColors.slate400,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$doctor • Trạng thái: $status',
                  style: const TextStyle(fontSize: 13, color: AppColors.slate600),
                ),
              ),
            ],
          ),
          if (symptoms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Triệu chứng: $symptoms',
              style: const TextStyle(fontSize: 12, color: AppColors.slate600),
            ),
          ],
          if (treatment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Hướng điều trị: $treatment',
              style: const TextStyle(fontSize: 12, color: AppColors.slate600),
            ),
          ],
          if (advice.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Lời dặn bác sĩ: $advice',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.slate700,
              ),
            ),
          ],
          if (followUp.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.amber500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Lịch hẹn tái khám: $followUp',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.amber500,
                ),
              ),
            ),
          ],
          if (labs.isNotEmpty) ...[
            const Divider(height: 20, color: AppColors.slate100),
            const Text(
              'Cận lâm sàng thực hiện:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.slate800,
              ),
            ),
            const SizedBox(height: 6),
            ...labs.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${l['ten_dich_vu']}: ${l['ket_qua']} (${l['trang_thai']})',
                    style: const TextStyle(fontSize: 12, color: AppColors.slate600),
                  ),
                )),
          ],
          if (medicines.isNotEmpty) ...[
            const Divider(height: 20, color: AppColors.slate100),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Đơn thuốc được kê:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate800,
                  ),
                ),
                if (donThuocTrangThai.isNotEmpty)
                  Text(
                    donThuocTrangThai,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.emerald500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ...medicines.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• ${m['ten_thuoc']} (${m['so_luong']} ${m['don_vi']}) — ${m['lieu_dung']} (${m['cach_dung']})',
                    style: const TextStyle(fontSize: 12, color: AppColors.slate700),
                  ),
                )),
            if (donThuocId != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _selectPurchaseOption(donThuocId, 'hospital'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.medical600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.local_pharmacy, size: 15),
                      label: const Text(
                        'Mua tại bệnh viện',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectPurchaseOption(donThuocId, 'outside'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.slate700,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.storefront, size: 15),
                      label: const Text(
                        'Tự mua ngoài',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
