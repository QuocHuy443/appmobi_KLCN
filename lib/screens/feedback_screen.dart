import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import '../core/patient_format.dart';
import '../widgets/request_error.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _api = PatientApiService();
  final _topic = TextEditingController(text: 'Dịch vụ khám bệnh');
  final _content = TextEditingController();
  final _form = GlobalKey<FormState>();
  List<Map<String, dynamic>> _history = [], _records = [];
  int _rating = 5;
  int? _encounter;
  String? _token, _error;
  bool _loading = false, _sending = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context.watch<AuthViewModel>().currentUser?.token;
    if (_token != token) {
      _token = token; _history = []; _records = [];
      if (token != null) _load(token);
    }
  }
  @override
  void dispose() { _topic.dispose(); _content.dispose(); super.dispose(); }
  Future<void> _load(String token) async {
    setState(() { _loading = true; _error = null; });
    try {
      final history = await _api.getFeedbacks(token);
      if (!mounted || _token != token) return;
      setState(() => _history = history);
      final records = await _api.getMedicalRecords(token);
      if (!mounted || _token != token) return;
      setState(() { _history = history; _records = List<Map<String,dynamic>>.from(records['records'] ?? []); _loading = false; });
    } catch (e) { if (mounted && _token == token) setState(() { _error = '$e'; _loading = false; }); }
  }
  Future<void> _send() async {
    if (_sending || _token == null || !_form.currentState!.validate()) return;
    final token = _token!;
    setState(() { _sending = true; _error = null; });
    try {
      await _api.submitFeedback(token: token, chuDe: _topic.text.trim(), diemDanhGia: _rating,
          noiDung: _content.text.trim(), encounterId: _encounter);
      if (!mounted || _token != token) return;
      _content.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi góp ý.')));
      await _load(token);
    } catch (e) { if (mounted && _token == token) setState(() => _error = '$e'); }
    finally { if (mounted) setState(() => _sending = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Góp ý & phản hồi')),
    body: _token == null ? const Center(child: Text('Vui lòng đăng nhập để gửi và xem góp ý.'))
      : RefreshIndicator(onRefresh: () => _load(_token!), child: ListView(padding: const EdgeInsets.all(20), children: [
        Form(key: _form, child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Gửi góp ý', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
          TextFormField(controller: _topic, maxLength: 200, decoration: const InputDecoration(labelText: 'Chủ đề'), validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập chủ đề' : null),
          DropdownButtonFormField<int>(initialValue: _rating, decoration: const InputDecoration(labelText: 'Mức đánh giá'), items: List.generate(5, (i) => DropdownMenuItem(value: i+1, child: Text('${i+1} sao'))), onChanged: _sending ? null : (v) => setState(() => _rating=v!)),
          DropdownButtonFormField<int>(initialValue: _encounter, isExpanded: true, decoration: const InputDecoration(labelText: 'Phiếu khám liên quan (tùy chọn)'), items: [const DropdownMenuItem<int>(value: null, child: Text('Không chọn')), ..._records.map((r) => DropdownMenuItem(value: r['id'] as int, child: Text('${r['ma_phieu'] ?? r['id']} — ${patientDate(r['thoi_gian_kham'])}', overflow: TextOverflow.ellipsis)))], onChanged: _sending ? null : (v) => setState(() => _encounter=v)),
          TextFormField(controller: _content, maxLength: 4000, minLines: 4, maxLines: 8, decoration: const InputDecoration(labelText: 'Nội dung'), validator: (v) => (v?.trim().length ?? 0) < 5 ? 'Nội dung cần ít nhất 5 ký tự' : null),
          FilledButton(onPressed: _sending ? null : _send, child: Text(_sending ? 'Đang gửi...' : 'Gửi góp ý')),
        ])))),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) RequestError(message: _error!, onRetry: () => _load(_token!)),
        const SizedBox(height: 20), const Text('Lịch sử phản hồi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (!_loading && _error == null && _history.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('Bạn chưa gửi góp ý nào.')),
        ..._history.map((item) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${item['chu_de'] ?? ''} • ${item['diem_danh_gia'] ?? ''}/5', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(patientDate(item['thoi_gian'] ?? item['ngay_gui'])),
          Text('Trạng thái: ${item['trang_thai'] ?? 'Chờ tiếp nhận'}'),
          if (item['ma_phieu'] != null) Text('Phiếu khám: ${item['ma_phieu']}'),
          const SizedBox(height: 8), Text('${item['noi_dung'] ?? ''}'), const Divider(),
          Text('Phòng khám phản hồi: ${item['tra_loi'] ?? item['phan_hoi_admin'] ?? item['phan_hoi'] ?? 'Chưa có phản hồi'}'),
          if (item['ngay_tra_loi'] != null) Text('Ngày trả lời: ${patientDate(item['ngay_tra_loi'])}'),
        ])))),
      ])),
  );
}
