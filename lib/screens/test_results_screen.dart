import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/patient_format.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import '../widgets/request_error.dart';
import 'auth_screen.dart';

class TestResultsScreen extends StatefulWidget {
  const TestResultsScreen({super.key});

  @override
  State<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends State<TestResultsScreen> {
  final PatientApiService _api = PatientApiService();
  final TextEditingController _searchController = TextEditingController();
  String? _token;
  String? _error;
  bool _loading = false;
  bool _imageLoading = false;
  String _typeFilter = 'all';
  List<Map<String, dynamic>> _items = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context.watch<AuthViewModel>().currentUser?.token;
    if (token != _token) {
      _token = token;
      _items = [];
      _error = null;
      if (token != null) _load(token);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load(String token) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.getLabResults(token);
      if (!mounted || _token != token) return;
      setState(() {
        _items = items;
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

  Future<void> _image(Map<String, dynamic> item) async {
    if (_imageLoading || _token == null) return;
    final token = _token!;
    setState(() => _imageLoading = true);
    try {
      final bytes = await _api.getLabImage(token, item['id'] as int);
      if (!mounted || _token != token) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '${item['ten_dich_vu'] ?? 'Ảnh kết quả cận lâm sàng'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.slate800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5,
                  child: Image.memory(
                    bytes,
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Không đọc được ảnh kết quả.'),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted && _token == token) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _imageLoading = false);
    }
  }

  bool _matchesCategory(Map<String, dynamic> item) {
    if (_typeFilter == 'all') return true;
    final rawType = '${item['loai_dich_vu'] ?? item['loai'] ?? ''}'.toLowerCase();
    if (_typeFilter == 'lab') {
      return rawType.contains('xét nghiệm') || rawType.contains('huyết') || rawType.contains('sinh hóa');
    }
    if (_typeFilter == 'imaging') {
      return !rawType.contains('xét nghiệm');
    }
    return true;
  }

  List<Map<String, dynamic>> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      if (!_matchesCategory(item)) return false;
      if (query.isEmpty) return true;
      final cls = item['cls'] is Map ? item['cls'] as Map : item;
      final text = [
        item['ten_dich_vu'],
        item['ten'],
        item['loai_dich_vu'],
        item['loai'],
        item['ma_phieu'],
        item['bac_si_chi_dinh'],
        item['chan_doan'],
        item['ket_qua'],
        cls['ket_luan'],
      ].map((e) => (e ?? '').toString().toLowerCase()).join(' ');
      return text.contains(query);
    }).toList();
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.slate800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _items.where((i) {
      final st = '${i['trang_thai'] ?? ''}'.toLowerCase();
      final kq = '${i['ket_qua'] ?? ''}'.trim();
      return st.contains('kết quả') || st.contains('hoàn thành') || kq.isNotEmpty;
    }).length;
    final encounterCount = _items
        .map((i) => '${i['ma_phieu'] ?? i['phieu_kham_id'] ?? ''}'.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .length;
    final filtered = _filteredItems;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Kết quả xét nghiệm và CĐHA',
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
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.biotech, size: 48, color: AppColors.medical600),
                    const SizedBox(height: 12),
                    const Text(
                      'Đăng nhập để xem kết quả xét nghiệm và chẩn đoán hình ảnh.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      ),
                      child: const Text('Đăng nhập'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _load(_token!),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      _buildStatCard(
                        'Tổng chỉ định',
                        '${_items.length}',
                        Icons.science_outlined,
                        AppColors.medical600,
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        'Đã có kết quả',
                        '$completedCount',
                        Icons.check_circle_outline,
                        AppColors.emerald500,
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        'Đợt khám',
                        '$encounterCount',
                        Icons.folder_shared_outlined,
                        AppColors.amber500,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên xét nghiệm, mã phiếu, bác sĩ...',
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Tất cả'),
                          selected: _typeFilter == 'all',
                          onSelected: (_) => setState(() => _typeFilter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Xét nghiệm'),
                          selected: _typeFilter == 'lab',
                          onSelected: (_) => setState(() => _typeFilter = 'lab'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Chẩn đoán hình ảnh'),
                          selected: _typeFilter == 'imaging',
                          onSelected: (_) => setState(() => _typeFilter = 'imaging'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_loading) const LinearProgressIndicator(),
                  if (_error != null)
                    RequestError(message: _error!, onRetry: () => _load(_token!)),
                  if (!_loading && _error == null && filtered.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: const Text(
                        'Chưa có kết quả đã được bác sĩ duyệt.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.slate600),
                      ),
                    ),
                  ...filtered.map((item) {
                    final cls = item['cls'] is Map ? item['cls'] as Map : item;
                    final measurements = cls['chi_so'];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.slate200),
                      ),
                      elevation: 0,
                      color: Colors.white,
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.medical50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.biotech_rounded,
                            color: AppColors.medical600,
                          ),
                        ),
                        title: Text(
                          '${item['ten_dich_vu'] ?? item['ten'] ?? ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate800,
                          ),
                        ),
                        subtitle: Text(
                          '${item['loai_dich_vu'] ?? item['loai'] ?? 'Cận lâm sàng'}\n${patientDate(item['thoi_gian_kham'])} • ${item['trang_thai'] ?? 'Đã có kết quả'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.slate500,
                          ),
                        ),
                        childrenPadding: const EdgeInsets.all(16),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Phiếu khám: ${item['ma_phieu'] ?? ''}'),
                          const SizedBox(height: 4),
                          Text('Bác sĩ chỉ định: ${item['bac_si_chi_dinh'] ?? ''}'),
                          if (item['chan_doan'] != null) ...[
                            const SizedBox(height: 4),
                            Text('Chẩn đoán: ${item['chan_doan']}'),
                          ],
                          const Divider(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.slate50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.slate200),
                            ),
                            child: SelectableText(
                              '${item['ket_qua'] ?? 'Chưa có nội dung kết quả'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate800,
                              ),
                            ),
                          ),
                          if (cls['don_vi'] != null) ...[
                            const SizedBox(height: 6),
                            Text('Đơn vị: ${cls['don_vi']}'),
                          ],
                          if (cls['khoang_tham_chieu'] != null) ...[
                            const SizedBox(height: 4),
                            Text('Khoảng tham chiếu: ${cls['khoang_tham_chieu']}'),
                          ],
                          if (cls['ket_luan'] != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Kết luận: ${cls['ket_luan']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.medical700,
                              ),
                            ),
                          ],
                          if (measurements is List)
                            ...measurements.whereType<Map>().map(
                                  (m) => Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '${m['ten'] ?? m['ten_chi_so'] ?? ''}: ${m['gia_tri'] ?? m['ket_qua'] ?? ''} ${m['don_vi'] ?? ''} • Tham chiếu: ${m['khoang_tham_chieu'] ?? ''}',
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 6),
                          Text(
                            'Thực hiện: ${item['nguoi_thuc_hien'] ?? item['bac_si_thuc_hien'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slate500,
                            ),
                          ),
                          if (item['file_endpoint'] != null) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _imageLoading ? null : () => _image(item),
                              icon: const Icon(Icons.image),
                              label: Text(
                                _imageLoading ? 'Đang tải ảnh...' : 'Xem ảnh kết quả',
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
