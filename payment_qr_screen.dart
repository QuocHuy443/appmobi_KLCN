import 'dart:async';
import 'dart:convert';

import 'package:file_selector/file_selector.dart' as selector;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_colors.dart';
import '../services/patient_api_service.dart';

String billMoney(dynamic value) =>
    '${NumberFormat.decimalPattern('vi_VN').format(num.tryParse('$value') ?? 0)} đ';

class PaymentQrScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> payment;
  final PatientApiService api;

  const PaymentQrScreen({super.key, required this.token,
    required this.payment, required this.api});

  @override
  State<PaymentQrScreen> createState() => _PaymentQrScreenState();
}

class _PaymentQrScreenState extends State<PaymentQrScreen> {
  Timer? _timer;
  bool _requestRunning = false;
  late int _remaining;
  String _message = 'Đang chờ xác nhận giao dịch...';

  @override
  void initState() {
    super.initState();
    _remaining = (widget.payment['expires_in_seconds'] as num?)?.toInt() ?? 600;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  Future<void> _poll() async {
    if (!mounted || _requestRunning) return;
    _remaining -= 3;
    if (_remaining <= 0) {
      _timer?.cancel();
      setState(() { _remaining = 0; _message = 'Hết thời gian chờ trên màn hình. Mở lại hóa đơn để kiểm tra.'; });
      return;
    }
    setState(() {});
    _requestRunning = true;
    try {
      final data = await widget.api.paymentStatus(
          widget.token, (widget.payment['invoice_id'] as num).toInt());
      if (!mounted) return;
      if (data['status'] == 'PAID' && data['invoice'] is Map) {
        _timer?.cancel();
        Navigator.of(context).pop(Map<String, dynamic>.from(data['invoice'] as Map));
      } else if (data['status'] == 'CANCELED') {
        _timer?.cancel();
        setState(() => _message = 'Hóa đơn đã hủy.');
      } else {
        setState(() => _message = 'Đang chờ xác nhận giao dịch...');
      }
    } catch (_) {
      if (mounted) setState(() => _message = 'Đang kết nối lại để kiểm tra giao dịch...');
    } finally {
      _requestRunning = false;
    }
  }

  static String _tlv(String tag, String value) =>
      '$tag${value.length.toString().padLeft(2, '0')}$value';

  static String _crc16Ccitt(String input) {
    var crc = 0xFFFF;
    for (final codeUnit in input.codeUnits) {
      crc ^= (codeUnit & 0xFF) << 8;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 0x8000) != 0 ? ((crc << 1) ^ 0x1021) & 0xFFFF : (crc << 1) & 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  static String _bankBin(String bankId) {
    const bins = {
      'MB': '970422',
      'MBBANK': '970422',
      'VCB': '970436',
      'VIETCOMBANK': '970436',
      'TCB': '970407',
      'TECHCOMBANK': '970407',
      'BIDV': '970418',
      'ICB': '970415',
      'CTG': '970415',
      'VIETINBANK': '970415',
      'ACB': '970416',
      'VPB': '970432',
      'VPBANK': '970432',
      'TPB': '970423',
      'TPBANK': '970423',
      'STB': '970403',
      'SACOMBANK': '970403',
      'VIB': '970441',
      'SHB': '970443',
      'MSB': '970426',
      'HDB': '970437',
      'OCB': '970448',
      'AGRIBANK': '970405',
      'VBA': '970405',
    };
    return bins[bankId.trim().toUpperCase()] ?? '970422';
  }

  static String _buildVietQrPayload(
      String bankId, String accountNo, String amount, String reference) {
    final beneficiary = _tlv('00', _bankBin(bankId)) + _tlv('01', accountNo.trim());
    final merchantInfo = _tlv('00', 'A000000727') +
        _tlv('01', beneficiary) +
        _tlv('02', 'QRIBFTTA');
    final extra = reference.trim().isNotEmpty ? _tlv('62', _tlv('08', reference.trim())) : '';
    final amt = int.tryParse(amount) ?? 0;
    final amountField = amt > 0 ? _tlv('54', amt.toString()) : '';
    final unsigned = _tlv('00', '01') +
        _tlv('01', amt > 0 ? '12' : '11') +
        _tlv('38', merchantInfo) +
        _tlv('53', '704') +
        amountField +
        _tlv('58', 'VN') +
        extra +
        '6304';
    return unsigned + _crc16Ccitt(unsigned);
  }

  Widget _buildLocalQr(String bankId, String accountNo, String amountRaw, String reference) {
    final payload = _buildVietQrPayload(bankId, accountNo, amountRaw, reference);
    return QrImageView(
      data: payload,
      version: QrVersions.auto,
      size: 220,
      backgroundColor: Colors.white,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
  }

  void _copyValue(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã sao chép $label: $value'), duration: const Duration(seconds: 2)),
    );
  }

  Widget _infoRow(String label, String value, {bool copyable = false, bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          ),
          Expanded(
            child: SelectableText(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
                fontSize: emphasize ? 15 : 14,
                color: emphasize ? AppColors.medical600 : Colors.black87,
              ),
            ),
          ),
          if (copyable && value.isNotEmpty) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _copyValue(label, value),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.copy_rounded, size: 16, color: AppColors.medical600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final clock = '${(_remaining ~/ 60).toString().padLeft(2, '0')}:${(_remaining % 60).toString().padLeft(2, '0')}';
    final qrUrl = (payment['qr_url'] ?? '').toString();
    final bankId = (payment['bank_id'] ?? '').toString();
    final accountNo = (payment['bank_account_no'] ?? '').toString();
    final accountName = (payment['bank_account_name'] ?? '').toString();
    final reference = (payment['reference'] ?? '').toString();
    final invoiceCode = (payment['ma_hoa_don'] ?? '').toString();
    final amountRaw = (payment['amount'] ?? 0).toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán VietQR')),
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460),
          child: Card(color: Colors.white, child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('PHÒNG KHÁM ĐA KHOA H2T CARE',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.medical600)),
              if (invoiceCode.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Hóa đơn: $invoiceCode', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: (kIsWeb || qrUrl.isEmpty)
                    ? _buildLocalQr(bankId, accountNo, amountRaw, reference)
                    : Image.network(
                        qrUrl,
                        width: 240,
                        height: 240,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox(
                            width: 240,
                            height: 240,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (_, __, ___) =>
                            _buildLocalQr(bankId, accountNo, amountRaw, reference),
                      ),
              ),
              const SizedBox(height: 14),
              Text(billMoney(payment['amount']),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                  color: AppColors.medical600)),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _infoRow('Ngân hàng', bankId),
                    const Divider(height: 1),
                    _infoRow('Số tài khoản', accountNo, copyable: true),
                    const Divider(height: 1),
                    _infoRow('Chủ tài khoản', accountName),
                    const Divider(height: 1),
                    _infoRow('Số tiền', billMoney(payment['amount']), copyable: true, emphasize: true),
                    if (amountRaw != '0') ...[
                      const Divider(height: 1),
                      _infoRow('Nội dung CK', reference, copyable: true, emphasize: true),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(_message, textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.medical600)),
              const SizedBox(height: 4),
              Text('Thời gian chờ: $clock', style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 12),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
            ]),
          ))),
      ))),
    );
  }
}

class BillScreen extends StatelessWidget {
  final Map<String, dynamic> invoice;

  const BillScreen({super.key, required this.invoice});

  String _escape(Object? value) => const HtmlEscape().convert('${value ?? ''}');

  String _billHtml() {
    final items = (invoice['chi_tiet'] as List? ?? []).whereType<Map>();
    final rows = items.map((item) => '<tr><td>${_escape(item['ten_khoan_thu'])}</td>'
        '<td>${_escape(item['so_luong'])}</td><td>${_escape(billMoney(item['don_gia']))}</td>'
        '<td>${_escape(billMoney(item['thanh_tien']))}</td></tr>').join();
    return '''<!doctype html><html lang="vi"><head><meta charset="utf-8"><title>Bill ${_escape(invoice['ma_hoa_don'])}</title>
<style>body{font:15px system-ui;max-width:800px;margin:30px auto;color:#1e293b}h1{color:#0f766e}table{width:100%;border-collapse:collapse}td,th{padding:8px;border-bottom:1px solid #cbd5e1;text-align:left}.paid{color:#047857;font-weight:bold}</style></head><body>
<h1>PHÒNG KHÁM ĐA KHOA H2T CARE</h1><p>${_escape(invoice['clinic_address'])}</p><h2>HÓA ĐƠN / BILL</h2><p class="paid">ĐÃ THANH TOÁN</p>
<p>Mã hóa đơn: ${_escape(invoice['ma_hoa_don'])}</p><p>Bệnh nhân: ${_escape(invoice['benh_nhan'])} (${_escape(invoice['ma_benh_nhan'])})</p>
<table><tr><th>Dịch vụ / Thuốc</th><th>SL</th><th>Đơn giá</th><th>Thành tiền</th></tr>$rows</table>
<p>Tổng chi phí: ${_escape(billMoney(invoice['tong_tien']))}</p><p>BHYT giảm trừ: ${_escape(billMoney(invoice['tien_bhyt']))}</p>
<p>Giảm khác: ${_escape(billMoney(invoice['giam_gia']))}</p><h2>Tổng thực thu: ${_escape(billMoney(invoice['thanh_tien']))}</h2>
<p>Phương thức: ${_escape(invoice['hinh_thuc_thanh_toan'])}</p><p>Thời gian thanh toán: ${_escape(invoice['thoi_gian_thanh_toan'])}</p>
</body></html>''';
  }

  Future<void> _saveBill(BuildContext context) async {
    final filename = 'H2T-Bill-${invoice['ma_hoa_don']}.html';
    final file = selector.XFile.fromData(Uint8List.fromList(utf8.encode(_billHtml())),
      mimeType: 'text/html', name: filename);
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux)) {
        final location = await selector.getSaveLocation(suggestedName: filename);
        if (location == null) return;
        await file.saveTo(location.path);
      } else {
        await Share.shareXFiles([file], fileNameOverrides: [filename]);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill đã sẵn sàng để lưu hoặc chia sẻ.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không lưu được Bill: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (invoice['chi_tiet'] as List? ?? []).whereType<Map>().toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Hóa đơn điện tử')),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('PHÒNG KHÁM ĐA KHOA H2T CARE',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold,
              color: AppColors.medical600)),
          Text('${invoice['clinic_address'] ?? ''}'),
          const SizedBox(height: 8),
          const Chip(label: Text('ĐÃ THANH TOÁN')),
          const SizedBox(height: 12),
          Text('Mã hóa đơn: ${invoice['ma_hoa_don']}'),
          Text('Bệnh nhân: ${invoice['benh_nhan']} (${invoice['ma_benh_nhan']})'),
          const Divider(height: 26),
          ...items.map((item) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${item['ten_khoan_thu']} × ${item['so_luong']}'),
            subtitle: Text('Đơn giá: ${billMoney(item['don_gia'])}'),
            trailing: Text(billMoney(item['thanh_tien'])),
          )),
          const Divider(height: 26),
          ListTile(title: const Text('Tổng chi phí'), trailing: Text(billMoney(invoice['tong_tien']))),
          ListTile(title: const Text('BHYT giảm trừ'), trailing: Text('- ${billMoney(invoice['tien_bhyt'])}')),
          if ((num.tryParse('${invoice['giam_gia']}') ?? 0) > 0)
            ListTile(title: const Text('Giảm khác'), trailing: Text('- ${billMoney(invoice['giam_gia'])}')),
          ListTile(title: const Text('Tổng thực thu', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(billMoney(invoice['thanh_tien']),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.medical600))),
          const Divider(height: 26),
          Text('Phương thức: ${invoice['hinh_thuc_thanh_toan']}'),
          Text('Thời gian thanh toán: ${invoice['thoi_gian_thanh_toan']}'),
          const SizedBox(height: 22),
          FilledButton.icon(onPressed: () => _saveBill(context),
            icon: const Icon(Icons.save_alt), label: const Text('Lưu Bill')),
          OutlinedButton(onPressed: () => Navigator.pop(context),
            child: const Text('Hoàn tất')),
        ]),
      ))),
    );
  }
}
