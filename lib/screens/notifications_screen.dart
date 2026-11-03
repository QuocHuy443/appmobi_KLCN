import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import 'auth_screen.dart';
import '../services/notification_navigation.dart';
import '../widgets/request_error.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final PatientApiService _apiService = PatientApiService();
  String? _lastToken;
  bool _isLoading = false;
  String _filter = 'all';
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

  Future<void> _loadNotifications(String token) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final list = await _apiService.getNotifications(token, tab: _filter);
      if (!mounted || token != _lastToken) return;
      setState(() {
        _items = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || token != _lastToken) return;
      setState(() { _isLoading = false; _error = '$e'; });
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Không thể đánh dấu đã đọc. Vui lòng thử lại.')));
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;

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
            'Thông Báo Y Tế',
            style: TextStyle(
              color: AppColors.slate800,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (user != null) PopupMenuButton<String>(
              tooltip: 'Lọc thông báo',
              initialValue: _filter,
              onSelected: (value) { _filter = value; _loadNotifications(user.token); },
              itemBuilder: (_) => const [PopupMenuItem(value: 'all', child: Text('Tất cả')),
                PopupMenuItem(value: 'appointment', child: Text('Lịch hẹn')),
                PopupMenuItem(value: 'exam', child: Text('Khám & xét nghiệm')),
                PopupMenuItem(value: 'pharmacy_billing', child: Text('Thuốc & viện phí'))]),
            if (user != null)
              IconButton(
                tooltip: 'Làm mới',
                icon: const Icon(Icons.refresh,
                    color: AppColors.medical600, size: 20),
                onPressed: () => _loadNotifications(user.token),
              ),
            if (user != null)
              TextButton.icon(
                onPressed: _marking ? null : () => _markRead(markAll: true),
                icon: const Icon(Icons.done_all,
                    size: 16, color: AppColors.medical600),
                label: const Text(
                  'Đã đọc',
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
              Tab(text: 'Lịch khám & Y tế'),
            ],
          ),
        ),
        body: user != null && _error != null ? Center(child: RequestError(message: _error!, onRetry: () => _loadNotifications(user.token))) : user == null
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
                      _buildList(_items),
                      _buildList(
                        _items.where((n) => n['da_xem'] != true).toList(),
                      ),
                      _buildList(
                        _items.where((n) {
                          final loai =
                              (n['loai'] ?? '').toString().toLowerCase();
                          final tieuDe =
                              (n['tieu_de'] ?? '').toString().toLowerCase();
                          final noiDung =
                              (n['noi_dung'] ?? '').toString().toLowerCase();
                          final combined = '$loai $tieuDe $noiDung';
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
                    ],
                  )),
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
                SizedBox(height: 120),
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
              itemBuilder: (context, index) {
                final item = list[index];
                final isUnread = item['da_xem'] != true;
                final title = (item['tieu_de'] ?? 'Thông báo').toString();
                final body = (item['noi_dung'] ?? '').toString();
                final time = (item['thoi_gian'] ?? '').toString();

                return GestureDetector(
                  onTap: () async {
                    if (isUnread && item['id'] is int) {
                      await _markRead(id: item['id'] as int);
                    }
                    if (!mounted || context.read<AuthViewModel>().currentUser?.profileComplete != true) return;
                    await openNotificationTarget(this.context, item['lien_ket']);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUnread
                          ? AppColors.medical50.withValues(alpha: 0.5)
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
                            color: AppColors.medical600.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.solidBell,
                              color: AppColors.medical600,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isUnread
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: AppColors.slate800,
                                      ),
                                    ),
                                  ),
                                  if (isUnread)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.rose500,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
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
                              const SizedBox(height: 8),
                              Text(
                                time,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.slate400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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
