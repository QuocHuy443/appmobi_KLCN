import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/notification_badge_widget.dart';
import '../notifications/notifications_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hóa đơn & Viện phí'),
        actions: [
          NotificationBadgeWidget(
            count: 0,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.medical600,
          unselectedLabelColor: AppColors.slate500,
          indicatorColor: AppColors.medical600,
          tabs: const [
            Tab(text: 'Chưa thanh toán'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUnpaidTab(context),
          _buildHistoryTab(context),
        ],
      ),
    );
  }

  Widget _buildUnpaidTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.medical500, AppColors.medical700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.medical600.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Tổng tiền cần thanh toán',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                '1,250,000 đ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Hạn chót: 23/09/2026',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text('Chi tiết hóa đơn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.slate800)),
        const SizedBox(height: 16),
        _buildBillItem('Phí khám bệnh', '150,000 đ'),
        _buildBillItem('Nội soi tai mũi họng', '350,000 đ'),
        _buildBillItem('Xét nghiệm máu cơ bản', '400,000 đ'),
        _buildBillItem('Thuốc theo đơn', '350,000 đ'),
        const Divider(height: 32, color: AppColors.slate300),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('1,250,000 đ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.medical600)),
          ],
        ),
        const SizedBox(height: 48),
        CustomButton(
          text: 'Thanh toán ngay',
          onPressed: () => _showPaymentModal(context),
        ),
      ],
    );
  }

  Widget _buildBillItem(String name, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(color: AppColors.slate600, fontSize: 15)),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate800, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHistoryCard(
          context,
          date: '15/08/2026',
          amount: '850,000 đ',
          status: 'Đã thanh toán',
          details: [
            {'name': 'Phí khám bệnh', 'price': '150,000 đ'},
            {'name': 'Siêu âm ổ bụng', 'price': '300,000 đ'},
            {'name': 'Thuốc', 'price': '400,000 đ'},
          ],
        ),
        const SizedBox(height: 16),
        _buildHistoryCard(
          context,
          date: '01/07/2026',
          amount: '450,000 đ',
          status: 'Đã thanh toán',
          details: [
            {'name': 'Phí khám bệnh', 'price': '150,000 đ'},
            {'name': 'Thuốc', 'price': '300,000 đ'},
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryCard(BuildContext context, {required String date, required String amount, required String status, required List<Map<String, String>> details}) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Chi tiết hóa đơn', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...details.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['name']!, style: const TextStyle(color: AppColors.slate600)),
                      Text(item['price']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )).toList(),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.medical600)),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng', style: TextStyle(color: AppColors.medical600)),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate200),
          boxShadow: [
            BoxShadow(
              color: AppColors.slate200.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(date, style: const TextStyle(color: AppColors.slate500, fontWeight: FontWeight.bold)),
                    Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate800)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.medical50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(color: AppColors.medical600, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              bottom: -10,
              child: Transform.rotate(
                angle: -0.2,
                child: Opacity(
                  opacity: 0.05,
                  child: Text(
                    'PAID',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: AppColors.medical600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn phương thức thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildPaymentMethodTile(Icons.credit_card, 'Thẻ ATM / Visa / Mastercard'),
            const SizedBox(height: 12),
            _buildPaymentMethodTile(Icons.account_balance_wallet, 'Ví MoMo', isSelected: true),
            const SizedBox(height: 12),
            _buildPaymentMethodTile(Icons.qr_code_scanner, 'Chuyển khoản ngân hàng (QR)'),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Xác nhận thanh toán',
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thanh toán thành công!'), backgroundColor: AppColors.medical600),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(IconData icon, String title, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.medical50 : Colors.white,
        border: Border.all(color: isSelected ? AppColors.medical500 : AppColors.slate200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: isSelected ? AppColors.medical600 : AppColors.slate600),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: AppColors.slate800))),
          if (isSelected) const Icon(Icons.check_circle, color: AppColors.medical600),
        ],
      ),
    );
  }
}
