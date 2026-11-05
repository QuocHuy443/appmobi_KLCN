import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/patient_format.dart';
import '../services/auth_service.dart';
import '../services/notification_navigation.dart';
import '../services/patient_api_service.dart';
import '../widgets/request_error.dart';
import 'auth_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final PatientApiService _apiService = PatientApiService();
  final TextEditingController _searchController = TextEditingController();
  String? _lastToken;
  bool _isLoading = false;
  String _filter = 'all';
  String _searchQuery = '';
  String? _error;
  bool _marking = false;
  List<Map<String, dynamic>> _items = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context.watch<AuthViewModel>().currentUser?.token;
    if (token != _lastToken) {
      _lastToken = token;
      if (token != null && token.isNotEmpty) {
        _loadNotifications(token);
      } else {
        setState(() {
          _items = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications(String token) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _apiService.getNotifications(token, tab: _filter);
      if (!mounted || token != _lastToken) return;
      setState(() {
        _items = list;
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

  Future<void> _markRead({int? id, bool markAll = false}) async {
    final token = context.read<AuthViewModel>().currentUser?.token;
    if (token == null || _marking) return;
    setState(() => _marking = true);
    try {
      await _apiService.markNotificationRead(
        token: token,
        id: id,
        markAll: markAll,
      );
      if (!mounted || token != _lastToken) return;
      await _loadNotifications(token);
    } catch (_) {
      if (!mounted || token != _lastToken) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể đánh dấu đã đọc. Vui lòng thử lại.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  Future<void> _handleItemTap(Map<String, dynamic> item) async {
    final isUnread = item['da_xem'] != true;
    final rawId = item['id'];
    final id = rawId is int ? rawId : int.tryParse('$rawId');
    if (isUnread && id != null) {
      await _markRead(id: id);
    }
    if (!mounted) return;
    final user = context.read<AuthViewModel>().currentUser;
    if (user?.profileComplete != true) return;
    await openNotificationTarget(
      context,
      item['lien_ket'],
      category: item['loai'] ?? item['loai_thong_bao'],
    );
  }

  (FaIconData, Color, Color) _styleForCategory(String rawCategory) {
    final loai = rawCategory.toLowerCase();
    if (loai.contains('lịch') ||
        loai.contains('hẹn') ||
        loai.contains('tái khám')) {
      return (
        FontAwesomeIcons.calendarCheck,
        Colors.indigo.shade600,
        Colors.indigo.shade50,
      );
    }
    if (loai.contains('kết quả') ||
        loai.contains('xét nghiệm') ||
        loai.contains('cận lâm sàng')) {
      return (
        FontAwesomeIcons.flaskVial,
        AppColors.emerald500,
        AppColors.medical50,
      );
    }
    if (loai.contains('khám')) {
      return (
        FontAwesomeIcons.stethoscope,
        AppColors.medical600,
        AppColors.medical50,
      );
    }
    if (loai.contains('thuốc')) {
      return (
        FontAwesomeIcons.pills,
        Colors.purple.shade600,
        Colors.purple.shade50,
      );
    }
    if (loai.contains('thanh toán') || loai.contains('hóa đơn')) {
      return (
        FontAwesomeIcons.receipt,
        Colors.amber.shade700,
        Colors.amber.shade50,
      );
    }
    if (loai.contains('phản hồi')) {
      return (
        FontAwesomeIcons.commentMedical,
        Colors.blue.shade600,
        Colors.blue.shade50,
      );
    }
    return (
      FontAwesomeIcons.solidBell,
      AppColors.medical600,
      AppColors.medical50,
    );
  }

  List<Map<String, dynamic>> _applySearch(List<Map<String, dynamic>> source) {
    if (_searchQuery.isEmpty) return source;
    final q = _searchQuery.toLowerCase();
    return source.where((n) {
      final combined = [
        n['tieu_de'],
        n['noi_dung'],
        n['loai'],
        n['loai_thong_bao'],
        n['thoi_gian'],
        n['thoi_gian_tao'],
      ].where((e) => e != null).join(' ').toLowerCase();
      return combined.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final unreadCount = _items.where((n) => n['da_xem'] != true).length;

    return DefaultTabController(
      length: 3,
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
            'Lịch Sử Thông Báo Y Tế',
            style: TextStyle(
              color: AppColors.slate800,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (user != null)
              PopupMenuButton<String>(
                tooltip: 'Lọc theo danh mục',
                initialValue: _filter,
                onSelected: (value) {
                  setState(() => _filter = value);
                  _loadNotifications(user.token);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'all', child: Text('Tất cả danh mục')),
                  PopupMenuItem(
                      value: 'appointment',
                      child: Text('Lịch hẹn và Tái khám')),
                  PopupMenuItem(
                      value: 'exam', child: Text('Kết quả và Khám bệnh')),
                  PopupMenuItem(
                      value: 'pharmacy_billing',
                      child: Text('Viện phí và Đơn thuốc')),
                ],
              ),
            if (user != null)
              IconButton(
                tooltip: 'Làm mới',
                icon: const Icon(
                  Icons.refresh,
                  color: AppColors.medical600,
                  size: 20,
                ),
                onPressed: () => _loadNotifications(user.token),
              ),
            if (user != null)
              TextButton.icon(
                onPressed: _marking ? null : () => _markRead(markAll: true),
                icon: const Icon(
                  Icons.done_all,
                  size: 16,
                  color: AppColors.medical600,
                ),
                label: const Text(
                  'Đã đọc hết',
                  style: TextStyle(
                    color: AppColors.medical600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.medical600,
            unselectedLabelColor: AppColors.slate400,
            indicatorColor: AppColors.medical600,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: 'Tất cả'),
              Tab(text: 'Chưa đọc'),
              Tab(text: 'Lịch khám và Y tế'),
            ],
          ),
        ),
        body: user != null && _error != null
            ? Center(
                child: RequestError(
                  message: _error!,
                  onRetry: () => _loadNotifications(user.token),
                ),
              )
            : user == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.bell,
                            size: 46,
                            color: AppColors.medical600,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Đăng nhập để xem thông báo lịch khám, kết quả xét nghiệm và nhắc uống thuốc.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14, color: AppColors.slate600),
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
                : Column(
                    children: [
                      // Thanh thống kê, tìm kiếm và lọc danh mục đồng nhất với bản Web
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.slate100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Tổng số: ${_items.length} thông báo',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.slate700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$unreadCount chưa đọc',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _searchController,
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v.trim()),
                              decoration: InputDecoration(
                                hintText: 'Tìm trong toàn bộ lịch sử thông báo...',
                                prefixIcon: const Icon(Icons.search, size: 19),
                                suffixIcon: _searchQuery.isEmpty
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.clear, size: 17),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      ),
                                isDense: true,
                                filled: true,
                                fillColor: AppColors.slate50,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.slate200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.slate200),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final cat in [
                                    ('all', 'Tất cả'),
                                    ('appointment', 'Lịch hẹn và Tái khám'),
                                    ('exam', 'Kết quả và Khám bệnh'),
                                    ('pharmacy_billing', 'Viện phí và Đơn thuốc'),
                                  ])
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ChoiceChip(
                                        label: Text(
                                          cat.$2,
                                          style: const TextStyle(fontSize: 11.5),
                                        ),
                                        selected: _filter == cat.$1,
                                        selectedColor: AppColors.medical100,
                                        onSelected: (_) {
                                          if (_filter == cat.$1) return;
                                          setState(() => _filter = cat.$1);
                                          _loadNotifications(user.token);
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : TabBarView(
                                children: [
                                  _buildList(_applySearch(_items)),
                                  _buildList(
                                    _applySearch(
                                      _items
                                          .where((n) => n['da_xem'] != true)
                                          .toList(),
                                    ),
                                  ),
                                  _buildList(
                                    _applySearch(
                                      _items.where((n) {
                                        final loai =
                                            (n['loai'] ?? n['loai_thong_bao'] ?? '')
                                                .toString()
                                                .toLowerCase();
                                        final tieuDe = (n['tieu_de'] ?? '')
                                            .toString()
                                            .toLowerCase();
                                        final noiDung = (n['noi_dung'] ?? '')
                                            .toString()
                                            .toLowerCase();
                                        final combined =
                                            '$loai $tieuDe $noiDung';
                                        return combined.contains('lịch') ||
                                            combined.contains('lich') ||
                                            combined.contains('hẹn') ||
                                            combined.contains('hen') ||
                                            combined.contains('khám') ||
                                            combined.contains('kham') ||
                                            combined.contains('tiếp nhận') ||
                                            combined.contains('tiep nhan') ||
                                            combined.contains('xác nhận') ||
                                            combined.contains('xac nhan') ||
                                            combined.contains('bác sĩ') ||
                                            combined.contains('bac si') ||
                                            combined.contains('xét nghiệm') ||
                                            combined.contains('x-quang') ||
                                            combined.contains('thuốc') ||
                                            combined.contains('toa') ||
                                            combined.contains('y tế') ||
                                            combined.contains('y te');
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list) {
    final user = context.read<AuthViewModel>().currentUser;
    return RefreshIndicator(
      onRefresh: () async {
        if (user != null) await _loadNotifications(user.token);
      },
      child: list.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Text(
                    'Không có thông báo nào trong mục này.',
                    style: TextStyle(color: AppColors.slate500, fontSize: 14),
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final item = list[index];
                final isUnread = item['da_xem'] != true;
                final title = (item['tieu_de'] ?? 'Thông báo').toString();
                final body = (item['noi_dung'] ?? '').toString();
                final rawTime =
                    (item['thoi_gian'] ?? item['thoi_gian_tao'] ?? '').toString();
                final time = patientDate(rawTime);
                final category =
                    (item['loai'] ?? item['loai_thong_bao'] ?? 'Hệ thống')
                        .toString();
                final hasLink = item['lien_ket'] != null &&
                    item['lien_ket'].toString().trim().isNotEmpty;
                final rawId = item['id'];
                final id = rawId is int ? rawId : int.tryParse('$rawId');
                final (iconData, iconColor, iconBg) =
                    _styleForCategory('$category $title');

                return GestureDetector(
                  onTap: () => _handleItemTap(item),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUnread
                          ? AppColors.medical50.withValues(alpha: 0.45)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUnread
                            ? AppColors.medical100
                            : AppColors.slate200,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: FaIcon(
                              iconData,
                              color: iconColor,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: isUnread
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        fontSize: 14,
                                        color: AppColors.slate900,
                                      ),
                                    ),
                                  ),
                                  if (isUnread) ...[
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.medical600,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.medical100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Mới',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.medical700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                body,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.slate600,
                                  height: 1.4,
                                ),
                              ),
                              if (time.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 13,
                                      color: AppColors.slate400,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      time,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.slate400,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.slate100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        category,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.slate600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (hasLink || isUnread) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    if (hasLink)
                                      InkWell(
                                        onTap: () => _handleItemTap(item),
                                        child: const Padding(
                                          padding:
                                              EdgeInsets.symmetric(vertical: 2),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Xem chi tiết',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.medical600,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              Icon(
                                                Icons.arrow_forward,
                                                size: 13,
                                                color: AppColors.medical600,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (isUnread && id != null)
                                      InkWell(
                                        onTap: _marking
                                            ? null
                                            : () => _markRead(id: id),
                                        child: const Padding(
                                          padding:
                                              EdgeInsets.symmetric(vertical: 2),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check,
                                                size: 13,
                                                color: AppColors.slate600,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Đánh dấu đã đọc',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.slate600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
