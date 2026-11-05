import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/patient_format.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import '../widgets/request_error.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  static const List<String> _presetTopics = [
    'Dịch vụ khám bệnh',
    'Thái độ phục vụ',
    'Cơ sở vật chất',
    'Thời gian chờ đợi và Quy trình',
    'Chi phí và Viện phí',
    'Góp ý khác',
  ];

  final PatientApiService _api = PatientApiService();
  final TextEditingController _topic =
      TextEditingController(text: 'Dịch vụ khám bệnh');
  final TextEditingController _content = TextEditingController();
  final GlobalKey<FormState> _form = GlobalKey<FormState>();

  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _records = [];
  int _rating = 5;
  int? _encounter;
  String? _token;
  String? _error;
  bool _loading = false;
  bool _sending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context.watch<AuthViewModel>().currentUser?.token;
    if (_token != token) {
      _token = token;
      _history = [];
      _records = [];
      if (token != null) _load(token);
    }
  }

  @override
  void dispose() {
    _topic.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _load(String token) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final history = await _api.getFeedbacks(token);
      if (!mounted || _token != token) return;
      setState(() => _history = history);
      final records = await _api.getMedicalRecords(token);
      if (!mounted || _token != token) return;
      setState(() {
        _history = history;
        _records = List<Map<String, dynamic>>.from(records['records'] ?? []);
        _loading = false;
      });
    } catch (e) {
      if (mounted && _token == token) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _send() async {
    if (_sending || _token == null || !_form.currentState!.validate()) return;
    final token = _token!;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _api.submitFeedback(
        token: token,
        chuDe: _topic.text.trim(),
        diemDanhGia: _rating,
        noiDung: _content.text.trim(),
        encounterId: _encounter,
      );
      if (!mounted || _token != token) return;
      _content.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi góp ý.')),
      );
      await _load(token);
    } catch (e) {
      if (mounted && _token == token) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Hòm thư Góp ý và Phản hồi',
          style: TextStyle(
            color: AppColors.slate800,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_token != null)
            IconButton(
              onPressed: _loading ? null : () => _load(_token!),
              icon: const Icon(Icons.refresh, color: AppColors.medical600),
            ),
        ],
      ),
      body: _token == null
          ? const Center(
              child: Text('Vui lòng đăng nhập để gửi và xem góp ý.'),
            )
          : RefreshIndicator(
              onRefresh: () => _load(_token!),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Form(
                    key: _form,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: AppColors.slate200),
                      ),
                      elevation: 0,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Gửi góp ý',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.slate800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Ý kiến đóng góp của bạn giúp Phòng khám H2T nâng cao chất lượng khám chữa bệnh mỗi ngày.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.slate500,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _presetTopics.map((preset) {
                                final selected = _topic.text.trim() == preset;
                                return ChoiceChip(
                                  label: Text(
                                    preset,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: selected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  selected: selected,
                                  onSelected: _sending
                                      ? null
                                      : (_) => setState(() => _topic.text = preset),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _topic,
                              maxLength: 200,
                              decoration: const InputDecoration(
                                labelText: 'Chủ đề',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Vui lòng nhập chủ đề'
                                      : null,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                final starVal = index + 1;
                                return IconButton(
                                  onPressed: _sending
                                      ? null
                                      : () => setState(() => _rating = starVal),
                                  icon: Icon(
                                    starVal <= _rating
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: AppColors.amber500,
                                    size: 30,
                                  ),
                                );
                              }),
                            ),
                            DropdownButtonFormField<int>(
                              initialValue: _rating,
                              decoration: const InputDecoration(
                                labelText: 'Mức đánh giá',
                                border: OutlineInputBorder(),
                              ),
                              items: List.generate(
                                5,
                                (i) => DropdownMenuItem(
                                  value: i + 1,
                                  child: Text('${i + 1} sao'),
                                ),
                              ),
                              onChanged: _sending
                                  ? null
                                  : (v) => setState(() => _rating = v!),
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<int>(
                              initialValue: _encounter,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Phiếu khám liên quan (tùy chọn)',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text('Không chọn'),
                                ),
                                ..._records.map(
                                  (r) => DropdownMenuItem(
                                    value: r['id'] as int,
                                    child: Text(
                                      '${r['ma_phieu'] ?? r['id']} — ${patientDate(r['thoi_gian_kham'])}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: _sending
                                  ? null
                                  : (v) => setState(() => _encounter = v),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _content,
                              maxLength: 4000,
                              minLines: 4,
                              maxLines: 8,
                              decoration: const InputDecoration(
                                labelText: 'Nội dung',
                                hintText:
                                    'Chia sẻ chi tiết trải nghiệm hoặc góp ý của bạn (tối thiểu 5 ký tự)...',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => (v?.trim().length ?? 0) < 5
                                  ? 'Nội dung cần ít nhất 5 ký tự'
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: _sending ? null : _send,
                              child: Text(_sending ? 'Đang gửi...' : 'Gửi góp ý'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_loading) const LinearProgressIndicator(),
                  if (_error != null)
                    RequestError(
                      message: _error!,
                      onRetry: () => _load(_token!),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lịch sử phản hồi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate800,
                        ),
                      ),
                      Text(
                        '${_history.length} mục',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (!_loading && _error == null && _history.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Bạn chưa gửi góp ý nào.'),
                    ),
                  ..._history.map((item) {
                    final replyText = (item['tra_loi'] ??
                            item['phan_hoi_admin'] ??
                            item['phan_hoi'] ??
                            'Chưa có phản hồi')
                        .toString();
                    final hasReply = replyText != 'Chưa có phản hồi' &&
                        replyText.trim().isNotEmpty;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.slate200),
                      ),
                      elevation: 0,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item['chu_de'] ?? ''} • ${item['diem_danh_gia'] ?? ''}/5',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.slate800,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hasReply
                                        ? AppColors.medical50
                                        : AppColors.slate100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Trạng thái: ${item['trang_thai'] ?? 'Chờ tiếp nhận'}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: hasReply
                                          ? AppColors.medical700
                                          : AppColors.slate600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              patientDate(item['thoi_gian'] ?? item['ngay_gui']),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.slate500,
                              ),
                            ),
                            if (item['ma_phieu'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Phiếu khám: ${item['ma_phieu']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.medical700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              '${item['noi_dung'] ?? ''}',
                              style: const TextStyle(
                                color: AppColors.slate700,
                                height: 1.4,
                              ),
                            ),
                            const Divider(height: 22),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: hasReply
                                    ? AppColors.medical50
                                    : AppColors.slate50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasReply
                                      ? AppColors.medical200
                                      : AppColors.slate200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Phòng khám phản hồi: $replyText',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: hasReply
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: hasReply
                                          ? AppColors.medical800
                                          : AppColors.slate600,
                                    ),
                                  ),
                                  if (item['ngay_tra_loi'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ngày trả lời: ${patientDate(item['ngay_tra_loi'])}',
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
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
