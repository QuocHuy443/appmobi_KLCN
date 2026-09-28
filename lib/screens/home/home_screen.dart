import 'package:flutter/material.dart';
import '../../widgets/header_widget.dart';
import '../../widgets/vip_card_widget.dart';
import '../../widgets/quick_services_widget.dart';
import '../../widgets/upcoming_appointment_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HeaderWidget(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VipCardWidget(),
                const SizedBox(height: 24),
                const Text('Tiện ích sức khỏe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const QuickServicesWidget(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Lịch khám sắp tới', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton(onPressed: () {}, child: const Text('Xem tất cả')),
                  ],
                ),
                const SizedBox(height: 8),
                const UpcomingAppointmentWidget(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}