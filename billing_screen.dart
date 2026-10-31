import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import 'auth_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final PatientApiService _apiService = PatientApiService();
  String? _lastToken;
  bool _isLoading = false;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _invoices = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context.watch<AuthViewModel>().currentUser?.token;
    if (token != _lastToken) {
      _lastToken = token;
      if (token != null && token.isNotEmpty) {
        _loadBilling(token);
      } else {
        setState(() {
          _stats = {};
          _invoices = [];
        });
      }
    }
  }

  Future<void> _loadBilling(String token) async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getBilling(token);
      if (!mounted) return;
      setState(() {
        if (data['stats'] is Map) {
          _stats = Map<String, dynamic>.from(data['stats'] as Map);
        } else {
          final hasBhyt = data['has_bhyt'] == true ||
              (data['so_the_bhyt'] != null &&
                  data['so_the_bhyt'].toString().isNotEmpty);
          _stats = {
            'has_bhyt': hasBhyt,
            'so_the_bhyt': data['so_the_bhyt'] ?? 'GD4797931100001',
          };
        }
        _invoices = List<Map<String, dynamic>>.from(data['invoices'] ?? []);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _formatVnd(dynamic value) {
    final numVal = (value is num)
        ? value.round()
        : (double.tryParse(value?.toString() ?? '0')?.round() ?? 0);
    final str = numVal.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final pos = str.length - i;
      buffer.write(str[i]);
      if (pos > 1 && pos % 3 == 1) {
        buffer.write('.');
      }
    }
    return '${buffer.toString()} ₫';
  }

  void _showPaymentGuideDialog(Map<String, dynamic> inv) {
    final code = (inv['ma_hoa_don'] ??
            inv['ma_hd'] ??
            'HD-${inv['id'].toString().padLeft(4, '0')}')
        .toString();
    final amount = _formatVnd(inv['thanh_tien']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Thanh toán hóa đơn $code',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Số tiền thực thu (sau trừ BHYT): $amount',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.rose500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.medical50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin chuyển khoản VietQR:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 6),
                  Text('• Ngân hàng: Vietcombank - CN TP.HCM', style: TextStyle(fontSize: 12)),
                  Text('• Số tài khoản: 1029384756', style: TextStyle(fontSize: 12)),
                  Text('• Chủ TK: PHONG KHAM DA KHOA H2T', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Nội dung CK: $code THANH TOAN VIEN PHI\nHoặc xuất trình mã $code tại Quầy Thu Ngân Tầng 1.',
              style: const TextStyle(fontSize: 12, color: AppColors.slate600),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.medical600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final unpaidList = _invoices
        .where((inv) => (inv['trang_thai'] ?? '') != 'Đã thanh toán')
        .toList();
    final paidList = _invoices
        .where((inv) => (inv['trang_thai'] ?? '') == 'Đã thanh toán')
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            'Thanh Toán Viện Phí & BHYT',
            style: TextStyle(
              color: AppColors.slate800,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (user != null)
              IconButton(
                onPressed: () => _loadBilling(user.token),
                icon: const Icon(Icons.refresh, color: AppColors.medical600),
              ),
          ],
          bottom: TabBar(
            labelColor: AppColors.medical600,
            unselectedLabelColor: AppColors.slate400,
            indicatorColor: AppColors.medical600,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: 'Cần thanh toán (${unpaidList.length})'),
              Tab(text: 'Lịch sử (${paidList.length})'),
            ],
          ),
        ),
        body: user == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.fileInvoiceDollar,
                        size: 46,
                        color: AppColors.medical600,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Vui lòng đăng nhập để tra cứu hóa đơn viện phí & mức khấu trừ BHYT 80%.',
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
                : TabBarView(
                    children: [
                      _buildPendingBillsTab(unpaidList),
                      _buildHistoryTab(paidList),
                    ],
                  )),
      ),
    );
  }

  Widget _buildPendingBillsTab(List<Map<String, dynamic>> unpaidList) {
    final hasBhyt = _stats['has_bhyt'] == true;
    final bhytCode = (_stats['so_the_bhyt'] ?? 'Chưa cập nhật').toString();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: hasBhyt ? AppColors.medical50 : AppColors.slate100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasBhyt ? AppColors.medical100 : AppColors.slate200,
            ),
          ),
          child: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.idCardClip,
                color: hasBhyt ? AppColors.medical600 : AppColors.slate500,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasBhyt
                      ? 'Thẻ BHYT: $bhytCode (Hưởng 80% chi phí theo quy định)'
                      : 'Chưa đăng ký thẻ BHYT (Cập nhật tại mục Tài khoản để hưởng BHYT)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasBhyt ? AppColors.medical600 : AppColors.slate600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (unpaidList.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.slate200),
            ),
            child: const Column(
              children: [
                FaIcon(
                  FontAwesomeIcons.circleCheck,
                  size: 40,
                  color: AppColors.emerald500,
                ),
                SizedBox(height: 12),
                Text(
                  'Bạn không có hóa đơn nào đang chờ thanh toán.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate700,
                  ),
                ),
              ],
            ),
          )
        else
          ...unpaidList.map((inv) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildInvoiceCard(inv, isPending: true),
              )),
      ],
    );
  }

  Widget _buildHistoryTab(List<Map<String, dynamic>> paidList) {
    if (paidList.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có lịch sử hóa đơn đã thanh toán.',
          style: TextStyle(color: AppColors.slate500, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: paidList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildInvoiceCard(paidList[index], isPending: false),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> inv, {required bool isPending}) {
    final code = (inv['ma_hoa_don'] ??
            inv['ma_hd'] ??
            'HD-${inv['id'].toString().padLeft(4, '0')}')
        .toString();
    final date = (inv['ngay_lap'] ?? '').toString();
    final status = (inv['trang_thai'] ?? '').toString();
    final items = List<Map<String, dynamic>>.from(inv['chi_tiet'] ?? inv['items'] ?? []);
    final dynamic rawTongTien = inv['tong_tien'] ?? 0;
    final dynamic rawTienBhyt = inv['tien_bhyt'] ?? inv['muc_bhyt_chi_tra'];
    final dynamic rawThanhTien = inv['thanh_tien'] ?? inv['thuc_thu'];

    final num tongTien = (rawTongTien is num) ? rawTongTien : (num.tryParse(rawTongTien?.toString() ?? '0') ?? 0);
    final num tienBhyt = (rawTienBhyt != null)
        ? ((rawTienBhyt is num) ? rawTienBhyt : (num.tryParse(rawTienBhyt.toString()) ?? 0))
        : (tongTien * 0.8);
    final num thanhTien = (rawThanhTien != null)
        ? ((rawThanhTien is num) ? rawThanhTien : (num.tryParse(rawThanhTien.toString()) ?? 0))
        : (tongTien - tienBhyt);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending ? AppColors.amber500 : AppColors.slate200,
          width: isPending ? 1.5 : 1,
        ),
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
                  color: isPending
                      ? AppColors.amber500.withValues(alpha: 0.12)
                      : AppColors.emerald500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isPending ? AppColors.amber500 : AppColors.emerald500,
                  ),
                ),
              ),
              Text(
                '$code • $date',
                style: const TextStyle(fontSize: 12, color: AppColors.slate400),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            (inv['chan_doan'] ?? 'Chi phí khám & điều trị').toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.slate800,
            ),
          ),
          const Divider(height: 24, color: AppColors.slate200),
          ...items.map((item) {
            final name = (item['ten_khoan_muc'] ??
                    item['ten_dich_vu'] ??
                    item['ten_khoan_thu'] ??
                    'Dịch vụ y tế')
                .toString();
            final qty = item['so_luong'] ?? 1;
            final itemTotal = item['thanh_tien'] ?? item['don_gia'] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildFeeRow(
                '$name (x$qty)',
                _formatVnd(itemTotal),
              ),
            );
          }),
          const Divider(height: 20, color: AppColors.slate100),
          _buildFeeRow('Tổng chi phí gốc', _formatVnd(tongTien)),
          const SizedBox(height: 6),
          _buildFeeRow(
            'BHYT chi trả (80%)',
            '- ${_formatVnd(tienBhyt)}',
            isDiscount: true,
          ),
          const Divider(height: 24, color: AppColors.slate200),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thực thu bệnh nhân',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800,
                ),
              ),
              Text(
                _formatVnd(thanhTien),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.rose500,
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => _showPaymentGuideDialog(inv),
                icon: const FaIcon(
                  FontAwesomeIcons.qrcode,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  'Thanh toán qua VietQR / Quầy thu ngân',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.medical600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeeRow(String title, String amount, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: isDiscount ? AppColors.emerald500 : AppColors.slate600,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDiscount ? AppColors.emerald500 : AppColors.slate800,
          ),
        ),
      ],
    );
  }
}
