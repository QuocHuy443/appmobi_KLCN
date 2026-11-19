import '../widgets/request_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import 'auth_screen.dart';
import 'payment_qr_screen.dart';

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
  void initState() {
    super.initState();
    PatientApiService.dataRevision.addListener(_onDataRevisionChanged);
  }

  @override
  void dispose() {
    PatientApiService.dataRevision.removeListener(_onDataRevisionChanged);
    super.dispose();
  }

  void _onDataRevisionChanged() {
    final token = _lastToken;
    if (mounted && token != null && token.isNotEmpty && !_isLoading) {
      _loadBilling(token);
    }
  }

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
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _apiService.getBilling(token);
      if (!mounted || token != _lastToken) return;
      setState(() {
        final rawStats = data['stats'] is Map
            ? Map<String, dynamic>.from(data['stats'] as Map)
            : (data['billing_stats'] is Map
                ? Map<String, dynamic>.from(data['billing_stats'] as Map)
                : <String, dynamic>{});
        final soTheBhyt =
            (rawStats['so_the_bhyt'] ?? data['so_the_bhyt'] ?? '').toString();
        final hasBhyt = rawStats['has_bhyt'] == true ||
            data['has_bhyt'] == true ||
            soTheBhyt.trim().isNotEmpty;
        _stats = {
          ...rawStats,
          'has_bhyt': hasBhyt,
          'so_the_bhyt': soTheBhyt,
          if (data['insurance_reduction'] != null)
            'insurance_reduction': data['insurance_reduction'],
          if (data['bhyt_percent'] != null)
            'bhyt_percent': data['bhyt_percent'],
        };
        _invoices = (data['invoices'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || token != _lastToken) return;
      setState(() {
        _isLoading = false;
        _error = '$e';
      });
    }
  }

  num _parseNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '0') ?? 0;
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

  bool _paymentLoading = false;
  String? _error;
  Future<void> _showPaymentGuideDialog(Map<String, dynamic> inv) async {
    final token = context.read<AuthViewModel>().currentUser?.token;
    if (_paymentLoading || token == null) return;
    setState(() => _paymentLoading = true);
    try {
      final data = await _apiService.paymentInstructions(
          token, (inv['id'] as num).toInt());
      if (!mounted || context.read<AuthViewModel>().currentUser?.token != token) return;
      if (data['payment'] is! Map) {
        throw Exception('Không nhận được thông tin thanh toán VietQR.');
      }
      final payment = data['payment'] as Map;
      final paidInvoice = await Navigator.push<Map<String, dynamic>>(context,
        MaterialPageRoute(builder: (_) => PaymentQrScreen(
          token: token, payment: Map<String, dynamic>.from(payment), api: _apiService)));
      if (!mounted || paidInvoice == null) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Thanh toán thành công!'), backgroundColor: AppColors.medical600));
      await _loadBilling(token);
      if (!mounted) return;
      await Navigator.push<void>(context, MaterialPageRoute(
        builder: (_) => BillScreen(invoice: paidInvoice)));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
    finally { if (mounted) setState(() => _paymentLoading = false); }
  }

  Future<void> _showCashGuidanceDialog(Map<String, dynamic> inv) async {
    final code = (inv['ma_hoa_don'] ?? inv['ma_hd'] ?? 'HD-${inv['id']}').toString();
    final amount = _formatVnd(inv['thanh_tien'] ?? inv['thuc_thu'] ?? 0);
    final token = context.read<AuthViewModel>().currentUser?.token;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.payments_outlined, color: AppColors.amber500, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Chỉ dẫn nộp viện phí bằng tiền mặt',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Địa điểm: Quầy Tiếp Tân và Thu Ngân (Tầng 1 - Sảnh chính)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mã hóa đơn: $code',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.medical700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Số tiền nộp: $amount',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.rose500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Vui lòng di chuyển đến Quầy Tiếp tân và đọc Mã hóa đơn hoặc Họ tên / SĐT của bạn.\n'
              '• Sau khi Tiếp tân xác nhận thu tiền mặt, hóa đơn sẽ tự động chuyển sang trạng thái Đã thanh toán và đơn thuốc sẽ được chuyển sang Nhà thuốc.',
              style: TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          if (token != null)
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await _loadBilling(token);
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Kiểm tra thanh toán'),
            ),
        ],
      ),
    );
  }

  Future<void> _showPaidBill(Map<String, dynamic> inv) async {
    final token = context.read<AuthViewModel>().currentUser?.token;
    if (token == null) return;
    try {
      final data = await _apiService.paymentStatus(token, (inv['id'] as num).toInt());
      if (!mounted) return;
      if (data['status'] != 'PAID' || data['invoice'] is! Map) {
        throw Exception('Hóa đơn chưa được xác nhận thanh toán.');
      }
      await Navigator.push<void>(context, MaterialPageRoute(
        builder: (_) => BillScreen(invoice: Map<String, dynamic>.from(data['invoice'] as Map))));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  Future<void> _exportCsv(String token) async {
    try {
      final res = await _apiService.exportBillingCsv(token);
      if (!mounted) return;
      final csvContent = (res['csv_content'] ?? '').toString();
      final filename = (res['filename'] ?? 'bang_ke_vien_phi.csv').toString();
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Bảng kê viện phí ($filename)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                csvContent.isEmpty
                    ? 'Chưa có dữ liệu hóa đơn.'
                    : csvContent,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: csvContent));
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.medical600,
                    content: Text('Đã sao chép bảng kê CSV vào bộ nhớ tạm!'),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Sao chép CSV'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final unpaidList = _invoices
        .where((inv) => (inv['trang_thai'] ?? '') == 'Chưa thanh toán')
        .toList();
    final paidList = _invoices
        .where((inv) => (inv['trang_thai'] ?? '') != 'Chưa thanh toán')
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
            'Thanh Toán Viện Phí và BHYT',
            style: TextStyle(
              color: AppColors.slate800,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (user != null) ...[
              IconButton(
                tooltip: 'Xuất bảng kê CSV',
                onPressed: () => _exportCsv(user.token),
                icon: const Icon(
                  Icons.download_outlined,
                  color: AppColors.medical600,
                ),
              ),
              IconButton(
                onPressed: () => _loadBilling(user.token),
                icon: const Icon(Icons.refresh, color: AppColors.medical600),
              ),
            ],
          ],
          bottom: TabBar(
            labelColor: AppColors.medical600,
            unselectedLabelColor: AppColors.slate400,
            indicatorColor: AppColors.medical600,
            indicatorWeight: 3,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: 'Cần thanh toán (${unpaidList.length})'),
              Tab(text: 'Lịch sử (${paidList.length})'),
            ],
          ),
        ),
        body: _error != null && user != null ? Center(child: RequestError(message: _error!, onRetry: () => _loadBilling(user.token))) : user == null
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
                        'Vui lòng đăng nhập để tra cứu chi phí khám chữa bệnh, khấu trừ BHYT và thanh toán viện phí.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 14, color: AppColors.slate600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AuthScreen()),
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

  Widget _buildStatsSummary(List<Map<String, dynamic>> unpaidList) {
    final activeInvoices = _invoices
        .where((inv) => (inv['trang_thai'] ?? '') != 'Đã hủy')
        .toList();
    final paidInvoices = activeInvoices
        .where((inv) => (inv['trang_thai'] ?? '') == 'Đã thanh toán')
        .toList();

    final num totalGross = _stats['tong_tien'] != null
        ? _parseNum(_stats['tong_tien'])
        : activeInvoices.fold<num>(
            0, (sum, inv) => sum + _parseNum(inv['tong_tien']));
    final num totalBhyt = _stats['tien_bhyt'] != null
        ? _parseNum(_stats['tien_bhyt'])
        : activeInvoices.fold<num>(
            0,
            (sum, inv) =>
                sum +
                _parseNum(inv['tien_bhyt_chi_tra'] ?? inv['tien_bhyt']));
    final num totalPaid = _stats['da_thanh_toan'] != null
        ? _parseNum(_stats['da_thanh_toan'])
        : paidInvoices.fold<num>(
            0, (sum, inv) => sum + _parseNum(inv['thanh_tien']));
    final num totalUnpaid = _stats['chua_thanh_toan'] != null
        ? _parseNum(_stats['chua_thanh_toan'])
        : unpaidList.fold<num>(
            0, (sum, inv) => sum + _parseNum(inv['thanh_tien']));
    final int totalCount = _stats['tong_so_hoa_don'] != null
        ? _parseNum(_stats['tong_so_hoa_don']).toInt()
        : activeInvoices.length;
    final int pendingCount = _stats['so_hoa_don_cho'] != null
        ? _parseNum(_stats['so_hoa_don_cho']).toInt()
        : unpaidList.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'Tổng viện phí KCB',
                  value: _formatVnd(totalGross),
                  subtext: '$totalCount hóa đơn phát sinh',
                  valueColor: AppColors.slate800,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  label: 'BHYT đồng chi trả',
                  value: _formatVnd(totalBhyt),
                  subtext: 'Khấu trừ BHYT hợp lệ',
                  valueColor: AppColors.emerald500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'Đã thanh toán',
                  value: _formatVnd(totalPaid),
                  subtext: 'Đã xuất biên lai điện tử',
                  valueColor: AppColors.medical600,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  label: 'Cần thanh toán',
                  value: _formatVnd(totalUnpaid),
                  subtext: '$pendingCount hóa đơn chờ',
                  valueColor: AppColors.amber500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String subtext,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.slate400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBillsTab(List<Map<String, dynamic>> unpaidList) {
    final hasBhyt = _stats['has_bhyt'] == true;
    final bhytCode = (_stats['so_the_bhyt'] ?? '').toString().trim();
    final bhytDisplay = bhytCode.isNotEmpty ? bhytCode : 'Đã đăng ký';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildStatsSummary(unpaidList),
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
                      ? 'Thẻ BHYT: $bhytDisplay (Khấu trừ BHYT hợp lệ theo danh mục dịch vụ KCB)'
                      : 'Chưa đăng ký thẻ BHYT (Cập nhật tại mục Tài khoản để hưởng quyền lợi BHYT)',
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

  Widget _buildInvoiceCard(Map<String, dynamic> inv,
      {required bool isPending}) {
    final code = (inv['ma_hoa_don'] ??
            inv['ma_hd'] ??
            'HD-${inv['id'].toString().padLeft(4, '0')}')
        .toString();
    final date = (inv['thoi_gian_tao'] ??
            inv['ngay_tao'] ??
            inv['ngay_lap'] ??
            inv['thoi_gian_thanh_toan'] ??
            '')
        .toString();
    final status = (inv['trang_thai'] ?? '').toString();
    final isPaid = status == 'Đã thanh toán';
    final isCanceled = status == 'Đã hủy';
    final drugReceiptStatus =
        (inv['trang_thai_nhan_thuoc'] ?? '').toString().trim();
    final paymentMethod = (inv['hinh_thuc_thanh_toan'] ??
            inv['phuong_thuc'] ??
            (isPaid ? 'Tiền mặt' : 'Chưa thanh toán'))
        .toString()
        .trim();
    final paymentTime = (inv['thoi_gian_thanh_toan'] ?? '').toString().trim();
    final cashierName = (inv['nhan_vien_thu'] ?? '').toString().trim();
    final maTheBhyt =
        (inv['ma_the_bhyt'] ?? inv['bhyt'] ?? _stats['so_the_bhyt'] ?? '')
            .toString()
            .trim();

    final items = (inv['chi_tiet'] as List? ?? inv['items'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final num tongTien = _parseNum(inv['tong_tien'] ?? inv['tong'] ?? 0);
    final num tienBhyt = _parseNum(
        inv['tien_bhyt'] ?? inv['tien_bhyt_chi_tra'] ?? inv['muc_bhyt_chi_tra'] ?? 0);
    final num giamGia = _parseNum(inv['giam_gia'] ?? 0);
    final num thanhTien = (inv['thanh_tien'] != null || inv['thuc_thu'] != null)
        ? _parseNum(inv['thanh_tien'] ?? inv['thuc_thu'])
        : (tongTien - tienBhyt - giamGia);

    final Color statusColor = isPending
        ? AppColors.amber500
        : (isCanceled ? AppColors.slate500 : AppColors.emerald500);

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
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  if (isPaid && drugReceiptStatus.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: drugReceiptStatus == 'Đã nhận thuốc'
                            ? AppColors.emerald500.withValues(alpha: 0.12)
                            : AppColors.amber500.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        drugReceiptStatus,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: drugReceiptStatus == 'Đã nhận thuốc'
                              ? AppColors.emerald500
                              : AppColors.amber500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  date.isNotEmpty ? '$code • $date' : code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.slate400),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            (inv['khoan_muc'] ??
                    inv['chan_doan'] ??
                    'Chi phí khám bệnh và thuốc')
                .toString(),
            style: const TextStyle(
              fontSize: 15,
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
            maTheBhyt.isNotEmpty && tienBhyt > 0
                ? 'BHYT giảm trừ (Thẻ: $maTheBhyt)'
                : 'BHYT giảm trừ',
            '- ${_formatVnd(tienBhyt)}',
            isDiscount: true,
          ),
          const SizedBox(height: 6),
          _buildFeeRow(
            'Giảm giá khác',
            '- ${_formatVnd(giamGia)}',
            isDiscount: giamGia > 0,
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
          if (isPaid) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phương thức thanh toán: $paymentMethod',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate700,
                    ),
                  ),
                  if (paymentTime.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Thời gian thanh toán: $paymentTime',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                  if (cashierName.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Người thu: $cashierName',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _paymentLoading
                          ? null
                          : () => _showPaymentGuideDialog(inv),
                      icon: const FaIcon(
                        FontAwesomeIcons.qrcode,
                        size: 15,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Thanh toán VietQR',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.medical600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showCashGuidanceDialog(inv),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    side: const BorderSide(color: AppColors.amber500),
                    foregroundColor: AppColors.slate800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.payments_outlined,
                    size: 16,
                    color: AppColors.amber500,
                  ),
                  label: const Text(
                    'Tiền mặt tại quầy',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isPaid) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showPaidBill(inv),
                icon: const Icon(Icons.receipt_long),
                label: const Text('Xem / Lưu Bill'),
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
