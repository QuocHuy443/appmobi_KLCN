import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import 'auth_screen.dart';

class TestResultsScreen extends StatefulWidget {
  const TestResultsScreen({super.key});

  @override
  State<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends State<TestResultsScreen> {
  final PatientApiService _apiService = PatientApiService();
  String? _lastToken;
  bool _isLoading = false;
  List<Map<String, dynamic>> _items = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context.watch<AuthViewModel>().currentUser?.token;
    if (token != _lastToken) {
      _lastToken = token;
      if (token != null && token.isNotEmpty) {
        _loadResults(token);
      } else {
        setState(() => _items = []);
      }
    }
  }

  Future<void> _loadResults(String token) async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getLabResults(token);
      if (!mounted) return;
      setState(() {
        _items = list;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const FaIcon(
            FontAwesomeIcons.arrowLeft,
            color: AppColors.slate800,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kết Quả Xét Nghiệm & CĐHA',
          style: TextStyle(
            color: AppColors.slate800,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (user != null)
            IconButton(
              onPressed: () => _loadResults(user.token),
              icon: const Icon(Icons.refresh, color: AppColors.medical600),
            ),
        ],
      ),
      body: user == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.flaskVial,
                      size: 46,
                      color: AppColors.medical600,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Vui lòng đăng nhập để xem Kết quả Xét nghiệm & Chẩn đoán hình ảnh từ cơ sở dữ liệu.',
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
                      child: const Text('Đăng nhập ngay'),
                    ),
                  ],
                ),
              ),
            )
          : (_isLoading
              ? const Center(child: CircularProgressIndicator())
              : (_items.isEmpty
                  ? const Center(
                      child: Text(
                        'Chưa có kết quả xét nghiệm / cận lâm sàng nào.',
                        style: TextStyle(color: AppColors.slate500, fontSize: 14),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return _buildLabCard(item);
                      },
                    ))),
    );
  }

  Widget _buildLabCard(Map<String, dynamic> item) {
    final serviceName = (item['ten_dich_vu'] ?? 'Xét nghiệm').toString();
    final groupName = (item['loai_dich_vu'] ?? 'Cận lâm sàng').toString();
    final resultText = (item['ket_qua'] ?? 'Đang chờ kết quả').toString();
    final status = (item['trang_thai'] ?? 'Đã có kết quả').toString();
    final examTime = (item['thoi_gian_kham'] ?? '').toString();
    final doctor = (item['bac_si_chi_dinh'] ?? 'Bác sĩ').toString();
    final technician = (item['nguoi_thuc_hien'] ?? 'KTV Xét nghiệm').toString();
    final diagnosis = (item['chan_doan'] ?? '').toString();
    final isCompleted = status.toLowerCase().contains('kết quả') ||
        status.toLowerCase().contains('hoàn thành');

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
                  groupName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.medical600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.emerald500.withValues(alpha: 0.12)
                      : AppColors.amber500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? AppColors.emerald500 : AppColors.amber500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            serviceName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ngày chỉ định: $examTime • BS: $doctor',
            style: const TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
          if (diagnosis.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Chẩn đoán: $diagnosis',
              style: const TextStyle(fontSize: 12, color: AppColors.slate600),
            ),
          ],
          const Divider(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slate100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kết luận / Chỉ số xét nghiệm:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  resultText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.medical600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Thực hiện bởi: $technician',
                  style: const TextStyle(fontSize: 11, color: AppColors.slate400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
