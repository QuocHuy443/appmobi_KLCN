import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import 'auth_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
        _loadNotifications(token);
      } else {
        setState(() => _items = []);
      }
    }
  }

  Future<void> _loadNotifications(String token) async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getNotifications(token);
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

  Future<void> _markRead({int? id, bool markAll = false}) async {
    final token = context.read<AuthViewModel>().currentUser?.token;
    if (token == null) return;
    try {
      await _apiService.markNotificationRead(
        token: token,
        id: id,
        markAll: markAll,
      );
      await _loadNotifications(token);
    } catch (_) {}
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
            if (user != null)
              TextButton(
                onPressed: () => _markRead(markAll: true),
                child: const Text(
                  'Đánh dấu đã đọc',
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
        body: user == null
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
                      _buildList(_items),
                      _buildList(
                        _items.where((n) => n['da_xem'] != true).toList(),
                      ),
                      _buildList(
                        _items
                            .where(
                              (n) => (n['loai'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .contains('lich'),
                            )
                            .toList(),
                      ),
                    ],
                  )),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'Không có thông báo nào trong mục này.',
          style: TextStyle(color: AppColors.slate500, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
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
          onTap: () {
            if (isUnread && item['id'] is int) {
              _markRead(id: item['id'] as int);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUnread
                  ? AppColors.medical50.withValues(alpha: 0.5)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnread ? AppColors.medical100 : AppColors.slate200,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    isUnread ? FontWeight.bold : FontWeight.w600,
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
    );
  }
}
